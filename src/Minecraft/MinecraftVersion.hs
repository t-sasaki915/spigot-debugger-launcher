module Minecraft.MinecraftVersion (MinecraftVersion(..), parseMinecraftVersion) where

import           Data.Text        (unpack)
import           Data.Yaml        (FromJSON (..), Value (..))
import           Text.Regex.Posix ((=~))

data MinecraftVersion = MinecraftVersion Int Int Int

instance Show MinecraftVersion where
    show (MinecraftVersion major minor 0) =
        show major ++ "." ++ show minor
    show (MinecraftVersion major minor patch) =
        show major ++ "." ++ show minor ++ "." ++ show patch

instance FromJSON MinecraftVersion where
    parseJSON (String txt) =
        case parseMinecraftVersion (unpack txt) of
            Just v  -> return v
            Nothing -> fail "Unrecognisable minecraft version"

    parseJSON _ = fail "Unrecognisable minecraft version"

parseMinecraftVersion :: String -> Maybe MinecraftVersion
parseMinecraftVersion str
    | str =~ "[0-9]+\\.[0-9]+\\.[0-9]+$" =
        let (major, str')  = takeWhileAndRemains (/= '.') str
            (minor, patch) = takeWhileAndRemains (/= '.') str' in
            Just (MinecraftVersion (read major) (read minor) (read patch))
    | str =~ "[0-9]+\\.[0-9]+$" =
        let (major, str') = takeWhileAndRemains (/= '.') str
            (minor, _)    = takeWhileAndRemains (/= '.') str' in
            Just (MinecraftVersion (read major) (read minor) 0)
    | otherwise = Nothing
    where
        takeWhileAndRemains f s =
            let taken = takeWhile f s in
                (taken, drop (length taken + 1) s)
