-- | General data types

module YAHDL.Types.General
  ( Token(..)
  , formatToken
  , VoiceState(..)
  , User(..)
  , Channel(..)
  , DM(..)
  , Guild(..)
  , Member(..)
  , Message(..)
  , Emoji(..)
  , Role(..)
  , Reaction(..)
  )
where

import           Data.Aeson

import           YAHDL.Types.Snowflake

data Token
  = BotToken ByteString
  | UserToken ByteString
  deriving (Generic, Show)

formatToken :: Token -> ByteString
formatToken (BotToken  t) = "Bot" <> t
formatToken (UserToken t) = t

data VoiceState = VoiceState
  { guildID   :: Maybe (Snowflake Guild)
  , channelID :: Maybe (Snowflake Channel)
  , userID    :: Snowflake User
  , member    :: Maybe Member
  , sessionID :: Text
  , deaf      :: Bool
  , mute      :: Bool
  , selfDeaf  :: Bool
  , selfMute  :: Bool
  , suppress  :: Bool
  } deriving (Show, Generic)

instance ToJSON VoiceState where
  toEncoding = genericToEncoding jsonOptions

instance FromJSON VoiceState where
  parseJSON = genericParseJSON jsonOptions

-- TODO: these types
newtype User = User Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype DM = DM Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Channel = Channel Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Guild = Guild Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Member = Member Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Message = Message Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Emoji = Emoji Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype Role = Role Value
  deriving (Show, Generic, ToJSON, FromJSON)

-- Needs to have user, message and emoji
newtype Reaction = Reaction Value
  deriving (Show, Generic, ToJSON, FromJSON)