{-# OPTIONS_GHC -Wno-partial-fields #-}

module Repl.Command.NewClientCommand (NewClientCommand(NewClientCommand)) where

import           Imports

import           AppState
import           Minecraft.Client.MinecraftClient (spawnMinecraftClient)
import           Repl.ReplCommand                 (ReplCommand (..))

import           Data.Bifunctor                   (first)
import           Data.Minecraft.MCVersion         (MCVersion (..),
                                                   mcVersionParser)
import           Options.Applicative

data NewClientCommand = NewClientCommand
                      | NewClientCommandOptions
                            { clientVersion  :: MCVersion
                            , clientUsername :: String
                            }

instance ReplCommand NewClientCommand where
    cmdDescription = const "Create a new Minecraft client."

    cmdArgParser = const newClientCommandArgParser

    cmdProcedure = newClientCommandProcedure

newClientCommandArgParser :: AppStateIO (Parser NewClientCommand)
newClientCommandArgParser = do
    defaultVersion  <- getClientDefaultVersion

    return $
        NewClientCommandOptions
            <$> option mcVersionParser
                ( long "version"
               <> short 'v'
               <> metavar "MinecraftVersion"
               <> value defaultVersion
               <> showDefault
               <> help "Specifies Minecraft client version."
                )
            <*> argument str
                ( metavar "Username"
               <> help "Specifies Minecraft client username."
                )

newClientCommandProcedure :: NewClientCommand -> AppStateIO ()
newClientCommandProcedure opts = do
    serverOnlineMode <- shouldServerUseOnlineMode
    when serverOnlineMode $
        error "The Minecraft server is using online mode. DEV clients are unusable."

    let cVersion  = clientVersion opts
        username = clientUsername opts

    when (cVersion < MCVersion 1 6 1) $
        error "Minecraft versions older than 1.6.1 are not supported."

    updateClientList

    clients <- getClients

    when (isJust $ lookup username (map (first runningClientName) clients)) $
        error (printf "A Minecraft client whose name is '%s' is existing." username)

    clientProcess <- spawnMinecraftClient cVersion username
    registerNewClient (ClientInfo username cVersion) clientProcess

    putStrLn' $
        printf "Successfully created a new Minecraft client with a name of '%s'. The game screen will be appeared soon." username
