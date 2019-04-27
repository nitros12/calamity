-- | module containing all dispatch events

module Calamity.Gateway.DispatchEvents where

import           Data.Aeson
import           Data.Time

import           Calamity.Types.General
import           Calamity.Types.UnixTimestamp
import           Calamity.Types.Snowflake

data DispatchData
  = Ready ReadyData
  | ChannelCreate Channel
  | ChannelUpdate Channel
  | ChannelDelete Channel
  | ChannelPinsUpdate ChannelPinsUpdateData
  | GuildCreate Guild
  | GuildUpdate UpdatedGuild
  | GuildDelete UnavailableGuild
  | GuildBanAdd GuildBanData
  | GuildBanRemove GuildBanData
  | GuildEmojisUpdate GuildEmojisUpdateData
  | GuildIntegrationsUpdate GuildIntegrationsUpdateData
  | GuildMemberAdd Member
  | GuildMemberRemove GuildMemberRemoveData
  | GuildMemberUpdate GuildMemberUpdateData
  | GuildMembersChunk GuildMembersChunkData
  | GuildRoleCreate GuildRoleData
  | GuildRoleUpdate GuildRoleData
  | GuildRoleDelete GuildRoleDeleteData
  | MessageCreate Message
  | MessageUpdate UpdatedMessage
  | MessageDelete MessageDeleteData
  | MessageDeleteBulk MessageDeleteBulkData
  | MessageReactionAdd Reaction
  | MessageReactionRemove Reaction
  | MessageReactionRemoveAll MessageReactionRemoveAllData
#ifdef PARSE_PRESENCES
  | PresenceUpdate Presence
#else
  | PresenceUpdate Value
#endif
  | TypingStart TypingStartData
  | UserUpdate User
  | VoiceStateUpdate VoiceStateUpdateData
  | VoiceServerUpdate VoiceServerUpdateData
  | WebhooksUpdate WebhooksUpdateData
  deriving (Show, Generic)

data ReadyData = ReadyData
  { v         :: Integer
  , user      :: User
  , guilds    :: [UnavailableGuild]
  , sessionID :: Text
  } deriving (Show, Generic)

instance FromJSON ReadyData where
  parseJSON = genericParseJSON jsonOptions

-- TODO: literally all of these

data ChannelPinsUpdateData = ChannelPinsUpdateData
  { channelID        :: Snowflake Channel
  , lastPinTimestamp :: Maybe UTCTime
  } deriving (Show, Generic)

instance FromJSON ChannelPinsUpdateData where
  parseJSON = genericParseJSON jsonOptions


data GuildBanData = GuildBanData
  { guildID :: Snowflake Guild
  , user    :: User
  } deriving (Show, Generic)

instance FromJSON GuildBanData where
  parseJSON = genericParseJSON jsonOptions


data GuildEmojisUpdateData = GuildEmojisUpdateData
  { guildID :: Snowflake Guild
  , emojis  :: [Emoji]
  } deriving (Show, Generic)

instance FromJSON GuildEmojisUpdateData where
  parseJSON = genericParseJSON jsonOptions


newtype GuildIntegrationsUpdateData = GuildIntegrationsUpdateData
  { guildID :: Snowflake Guild
  } deriving (Show, Generic)

instance FromJSON GuildIntegrationsUpdateData where
  parseJSON = genericParseJSON jsonOptions


data GuildMemberRemoveData = GuildMemberRemoveData
  { guildID :: Snowflake Guild
  , user    :: User
  } deriving (Show, Generic)

instance FromJSON GuildMemberRemoveData where
  parseJSON = genericParseJSON jsonOptions


data GuildMemberUpdateData = GuildMemberUpdateData
  { guildID :: Snowflake Guild
  , roles   :: [Snowflake Role]
  , user    :: User
  , nick    :: Maybe Text
  } deriving (Show, Generic)

instance FromJSON GuildMemberUpdateData where
  parseJSON = genericParseJSON jsonOptions


data GuildMembersChunkData = GuildMembersChunkData
  { guildID :: Snowflake Guild
  , members :: [Member]
  } deriving (Show, Generic)

instance FromJSON GuildMembersChunkData where
  parseJSON = withObject "GuildMembersChunkData" $ \v -> do
    guildID <- v .: "guild_id"

    members' <- do
      members' <- v .: "members"
      mapM (\m -> parseJSON $ Object (m <> "guild_id" .= guildID)) members'

    pure $ GuildMembersChunkData guildID members'


data GuildRoleData = GuildRoleData
  { guildID :: Snowflake Guild
  , role    :: Role
  } deriving (Show, Generic)

instance FromJSON GuildRoleData where
  parseJSON = genericParseJSON jsonOptions


data GuildRoleDeleteData = GuildRoleDeleteData
  { guildID :: Snowflake Guild
  , roleID  :: Snowflake Role
  } deriving (Show, Generic)

instance FromJSON GuildRoleDeleteData where
  parseJSON = genericParseJSON jsonOptions


data MessageDeleteData = MessageDeleteData
  { id        :: Snowflake Message
  , channelID :: Snowflake Channel
  , guildID   :: Snowflake Guild
  } deriving (Show, Generic)

instance FromJSON MessageDeleteData where
  parseJSON = genericParseJSON jsonOptions


data MessageDeleteBulkData = MessageDeleteBulkData
  { guildID   :: Snowflake Guild
  , channelID :: Snowflake Channel
  , ids       :: [Snowflake Message]
  } deriving (Show, Generic)

instance FromJSON MessageDeleteBulkData where
  parseJSON = genericParseJSON jsonOptions


data MessageReactionRemoveAllData = MessageReactionRemoveAllData
  { channelID :: Snowflake Channel
  , messageID :: Snowflake Message
  , guildID   :: Maybe (Snowflake Guild)
  } deriving (Show, Generic)

instance FromJSON MessageReactionRemoveAllData where
  parseJSON = genericParseJSON jsonOptions


data TypingStartData = TypingStartData
  { channelID :: Snowflake Channel
  , guildID   :: Snowflake Guild
  , userID    :: Snowflake User
  , timestamp :: UnixTimestamp
  } deriving (Show, Generic)

instance FromJSON TypingStartData where
  parseJSON = genericParseJSON jsonOptions


newtype VoiceStateUpdateData = VoiceStateUpdateData Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype VoiceServerUpdateData = VoiceServerUpdateData Value
  deriving (Show, Generic, ToJSON, FromJSON)

newtype WebhooksUpdateData = WebhooksUpdateData Value
  deriving (Show, Generic, ToJSON, FromJSON)
