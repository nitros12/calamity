-- | The route type
-- Why I did this I don't know
{-# OPTIONS_GHC -Wno-unused-top-binds #-}

module Calamity.HTTP.Internal.Route
    ( mkRouteBuilder
    , giveID
    , buildRoute
    , RouteBuilder
    , RouteRequirement
    , Route(path)
    , S(..)
    , ID(..)
    , RouteFragmentable(..) ) where

import           Calamity.Types.Model.Channel
import           Calamity.Types.Model.Guild
import           Calamity.Types.Snowflake

import           Data.Hashable
import           Data.Kind
import           Data.Maybe                   ( fromJust )
import           Data.Text                    ( Text )
import qualified Data.Text                    as T
import           Data.Typeable
import           Data.Word
import           Data.List ( foldl' )

import           Network.HTTP.Req

import           GHC.Generics                 hiding ( S )

import           TextShow

data RouteFragment
  = S' Text
  | ID' TypeRep
  deriving ( Generic, Show, Eq )

newtype S = S Text

data ID a = ID

instance Hashable RouteFragment

data RouteRequirement
  = NotNeeded
  | Required
  | Satisfied
  deriving ( Generic, Show, Eq )

data RouteBuilder (idState :: [(Type, RouteRequirement)]) = UnsafeMkRouteBuilder
  { route :: [RouteFragment]
  , ids   :: [(TypeRep, Word64)]
  }

mkRouteBuilder :: RouteBuilder '[]
mkRouteBuilder = UnsafeMkRouteBuilder [] []

giveID
  :: forall k ids
   . Typeable k
  => Snowflake k
  -> RouteBuilder ids
  -> RouteBuilder ('(k, 'Satisfied) ': ids)
giveID (Snowflake id) (UnsafeMkRouteBuilder route ids) =
  UnsafeMkRouteBuilder route ((typeRep (Proxy @k), id) : ids)

type family (&&) (a :: Bool) (b :: Bool) :: Bool where
  'True && 'True = 'True
  _     && _     = 'False

type family Lookup (x :: k) (l :: [(k, v)]) :: Maybe v where
  Lookup k ('(k, v) ': xs) = 'Just v
  Lookup k ('(_, v) ': xs) = Lookup k xs
  Lookup _ '[]             = 'Nothing

type family IsElem (x :: k) (l :: [k]) :: Bool where
  IsElem _ '[]      = 'False
  IsElem k (k : _)  = 'True
  IsElem k (_ : xs) = IsElem k xs

type family EnsureFulfilled (ids :: [(k, RouteRequirement)]) :: Constraint where
  EnsureFulfilled ids = EnsureFulfilledInner ids '[] 'True

type family EnsureFulfilledInner (ids :: [(k, RouteRequirement)]) (seen :: [k]) (ok :: Bool) :: Constraint where
  EnsureFulfilledInner '[]                      _    'True = ()
  EnsureFulfilledInner ('(k, 'NotNeeded) ': xs) seen ok    = EnsureFulfilledInner xs (k ': seen) ok
  EnsureFulfilledInner ('(k, 'Satisfied) ': xs) seen ok    = EnsureFulfilledInner xs (k ': seen) ok
  EnsureFulfilledInner ('(k, 'Required)  ': xs) seen ok    = EnsureFulfilledInner xs (k ': seen) (IsElem k seen && ok)

type family AddRequired k (ids :: [(Type, RouteRequirement)]) :: [(Type, RouteRequirement)] where
  AddRequired k ids = '(k, AddRequiredInner (Lookup k ids)) ': ids

type family AddRequiredInner (k :: Maybe RouteRequirement) :: RouteRequirement where
  AddRequiredInner ('Just 'Required)  = 'Required
  AddRequiredInner ('Just 'Satisfied) = 'Satisfied
  AddRequiredInner ('Just 'NotNeeded) = 'Required
  AddRequiredInner 'Nothing           = 'Required

class Typeable a => RouteFragmentable a ids where
  type ConsRes a ids

  (//) :: RouteBuilder ids -> a -> ConsRes a ids

instance RouteFragmentable S ids where
  type ConsRes S ids = RouteBuilder ids

  (UnsafeMkRouteBuilder r ids) // (S t) =
    UnsafeMkRouteBuilder (r <> [S' t]) ids

instance Typeable a => RouteFragmentable (ID (a :: Type)) (ids :: [(Type, RouteRequirement)]) where
  type ConsRes (ID a) ids = RouteBuilder (AddRequired a ids)

  (UnsafeMkRouteBuilder r ids) // ID =
    UnsafeMkRouteBuilder (r <> [ID' (typeRep (Proxy @a))]) ids

infixl 5 //

data Route = Route
  { path      :: Url 'Https
  , key       :: Text
  , channelID :: Maybe (Snowflake Channel)
  , guildID   :: Maybe (Snowflake Guild)
  } deriving (Generic, Show, Eq)

instance Hashable Route where
  hashWithSalt s (Route _ ident c g) = hashWithSalt s (ident, c, g)

baseURL :: Url 'Https
baseURL = https "discord.com" /: "api" /: "v8"

buildRoute
  :: forall (ids :: [(Type, RouteRequirement)])
   . EnsureFulfilled ids
  => RouteBuilder ids
  -> Route
buildRoute (UnsafeMkRouteBuilder route ids) = Route
  (foldl' (/:) baseURL $ map goR route)
  (T.concat (map goIdent route))
  (Snowflake <$> lookup (typeRep (Proxy @Channel)) ids)
  (Snowflake <$> lookup (typeRep (Proxy @Guild)) ids)
 where
  goR (S'  t) = t
  goR (ID' t) = showt . fromJust $ lookup t ids

  goIdent (S'  t) = t
  goIdent (ID' t) = showt t
