{-# LANGUAGE OverloadedStrings #-}

module Config.Config
    ( Config(..)
    , ApplicationConfig(..)
    , ServerConfig(..)
    , ClientConfig(..)
    ) where

import           Minecraft.MinecraftVersion   (MinecraftVersion)
import           Minecraft.Server.ServerBrand (ServerBrand)

import           Data.Yaml                    (FromJSON (..), Value (..), (.:))

data Config = Config
    { applicationConfig :: ApplicationConfig
    , serverConfig      :: ServerConfig
    , clientConfig      :: ClientConfig
    }
    deriving Show

newtype ApplicationConfig = ApplicationConfig
    { workingDir :: FilePath
    }
    deriving Show

data ServerConfig = ServerConfig
    { serverBrand         :: ServerBrand
    , serverVersion       :: MinecraftVersion
    , serverJvmOptions    :: [String]
    , serverOnlineMode    :: Bool
    , serverStaticPlugins :: [FilePath]
    }
    deriving Show

data ClientConfig = ClientConfig
    { clientDefaultVersion  :: MinecraftVersion
    , clientDefaultUsername :: String
    , clientJvmOptions      :: [String]
    }
    deriving Show

instance FromJSON ClientConfig where
    parseJSON (Object m) =
        ClientConfig
            <$> m .: "defaultVersion"
            <*> m .: "defaultUsername"
            <*> m .: "jvmOptions"

    parseJSON _ = fail "Unrecognisable client config"

instance FromJSON ServerConfig where
    parseJSON (Object m) =
        ServerConfig
            <$> m .: "brand"
            <*> m .: "version"
            <*> m .: "jvmOptions"
            <*> m .: "onlineMode"
            <*> m .: "staticPlugins"

    parseJSON _ = fail "Unrecognisable server config"

instance FromJSON ApplicationConfig where
    parseJSON (Object m) =
        ApplicationConfig
            <$> m .: "workingDir"

    parseJSON _ = fail "Unrecognisable application config"

instance FromJSON Config where
    parseJSON (Object m) =
        Config
            <$> m .: "application"
            <*> m .: "server"
            <*> m .: "client"

    parseJSON _ = fail "Unrecognisable config"
