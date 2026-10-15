# OrangeLen app icon

The orange folder represents projects and their files. The two cards inside it
represent AI outputs: a neural network and generated content. The glass lens and
code chevrons represent quick inspection of those outputs.

- `OrangeLen-icon.png`: original master generated with the built-in Imagegen tool.
- `imagegen-prompt.txt`: the final edit prompt.
- `../../App/Resources/OrangeLen.icns`: native application icon, including standard
  and Retina representations from 16 to 1024 pixels.

To regenerate the ICNS after replacing the master:

```sh
./scripts/build-app-icon.sh
```

`project.yml` declares `CFBundleIconFile`; the committed Xcode project copies the
ICNS into the application resources. Both development and release packaging check
that the icon is present before producing the archive. The ZIP contains the app
with its icon; the ZIP file itself keeps the system archive icon.
