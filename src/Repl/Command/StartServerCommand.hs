{-# OPTIONS_GHC -Wno-partial-fields #-}

module Repl.Command.StartServerCommand (StartServerCommand(StartServerCommand)) where

import           Imports

import           AppState
import           Minecraft.Server.MinecraftServer      (runMinecraftServer)
import           Minecraft.Server.MinecraftServerSetup (editServerProperties,
                                                        setupMinecraftServer)
import           Repl.ReplCommand                      (ReplCommand (..),
                                                        confirmContinue)

import           Data.Minecraft.MCProperty
import           Data.Minecraft.MCServerBrand          (getMCServerExecutableName)
import           Options.Applicative

data StartServerCommand = StartServerCommand
                        | StartServerCommandOptions
                            { acceptEula :: Bool
                            }

instance ReplCommand StartServerCommand where
    cmdDescription = const "Start the Minecraft server."

    cmdArgParser = const startServerCommandArgParser

    cmdProcedure = startServerCommandProcedure

startServerCommandArgParser :: AppStateIO (Parser StartServerCommand)
startServerCommandArgParser =
    return $
        StartServerCommandOptions
            <$> switch
                ( long "acceptEula"
               <> short 'a'
               <> help "Accept the Minecraft Eula and skip confirming."
                )

startServerCommandProcedure :: StartServerCommand -> AppStateIO ()
startServerCommandProcedure opts = do
    updateServerProc

    whenM (getServerProc <&> isJust) $
        error "The Minecraft server has been started already."

    workingDir    <- getWorkingDir
    serverVersion <- getServerVersion
    serverBrand   <- getMCServerBrand

    let serverJarPath = workingDir </> getMCServerExecutableName serverBrand serverVersion

    unlessM (lift (doesFileExist serverJarPath)) $ do
        putStrLn' (printf "Could not find '%s'. Need to download." serverJarPath)

        setupMinecraftServer

        putStrLn' "Successfully downloaded the Minecraft server."

    checkEula (acceptEula opts)

    editServerProperties

    serverHandle <- runMinecraftServer
    registerServer serverHandle

    putStrLn' "Successfully started the Minecraft server. The console will be appeared soon."


checkEula :: Bool -> AppStateIO ()
checkEula skip = do
    workingDir <- getWorkingDir
    let eulaFilePath = workingDir </> "eula.txt"

    let accepted = newMCProperties $ addProperty "eula" (MCBool True)
        isAccepted = lift (doesFileExist eulaFilePath) >>= \case
                True -> do
                    eulaFileContent <- lift (readFile eulaFilePath)

                    case decodeMCProperties eulaFileContent of
                        Right properties ->
                            case mcPropertiesWork (getProperty "eula") properties of
                                Just (MCBool True) -> return True
                                _                  -> return False

                        Left err ->
                            error (printf "Failed to parse eula.txt: %s." err)

                False ->
                    return False

    unlessM isAccepted $ do
        unless skip $ do
            putStrLn' "To continue, you have to accept the Minecraft Eula:"
            putStrLn' "https://aka.ms/MinecraftEULA"
            putStrLn' ""

            unlessM confirmContinue $
                error "The operation has cancelled."

        lift (writeFile eulaFilePath (encodeMCProperties accepted))
