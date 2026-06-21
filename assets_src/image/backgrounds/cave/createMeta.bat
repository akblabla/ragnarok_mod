@echo off
setlocal

for %%F in (*.ase) do (
    (
        echo ---
		echo atlas: backgrounds/map_backgrounds_RagnarokMod
		echo ...


    ) > "%%~nF.ase.meta"
)

echo Done.
pause