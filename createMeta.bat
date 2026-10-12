@echo off
setlocal

for %%F in (*.ase) do (
    (
        echo ---
		echo - data:
		echo     pivotX: 0
		echo     pivotY: 24
		echo     atlas: terrain_tall_tilesets
		echo     material: Halley/Sprite
		echo ...

    ) > "%%~nF.ase.meta"
)

echo Done.
pause