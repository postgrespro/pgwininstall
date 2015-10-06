AddToPath plugin for NSIS
Add and remove record from PATH environment variable

For use copy AddToPath.dll to Plugins directoty of NSIS

Usage example in NSIS:
AddToPath::AddToPath "$INSTDIR\bin"

AddToPath::RemoveFromPath "$INSTDIR\bin"

