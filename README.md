# Linux workstation setup

Instalador y dotfiles para dejar una máquina Linux lista: zsh + Powerlevel10k,
kitty, fuentes Nerd, herramientas de CLI, apps de escritorio y CLIs de IA.

Probado en Ubuntu 26.04. Detecta `apt`, `dnf`, `yum` y `pacman`, así que en
Debian/Fedora/RHEL/Arch debería funcionar en modo "mejor esfuerzo".

## Requisitos

- `bash`, `git`, `curl` y `sudo`
- Ejecutarlo **como tu usuario normal**, no con `sudo` (el script pide sudo
  donde hace falta y necesita tu `$HOME` real).

## Uso

```bash
git clone https://github.com/cfpandrade/Linux
cd Linux
./install.sh                  # todo
./install.sh --dry-run        # enseña lo que haría, sin tocar nada
./install.sh zsh kitty llm    # solo algunos módulos
./install.sh --list           # lista los módulos
```

## Módulos

| Módulo       | Qué hace |
|--------------|----------|
| `system`     | Paquetes base de la distro (zsh, git, ripgrep, bat, lsd, duf, boxes, ratbagd…) |
| `upgrade`    | `update` + `full-upgrade` + `autoremove` |
| `git`        | Config global: `delta` como pager, `pull.ff only`, `zdiff3`… |
| `fonts`      | Hack Nerd Fonts en `~/.local/share/fonts` |
| `zsh`        | `.zshrc`, `.p10k.zsh`, tmux, funciones y plugins de zsh |
| `p10k`       | Powerlevel10k en `/usr/share/powerlevel10k` |
| `shelltools` | fzf, zoxide y atuin |
| `kitty`      | Última versión desde el instalador oficial + configuración |
| `llm`        | Node.js y los CLIs de IA |
| `lazydocker` | lazydocker |
| `snap`       | Aplicaciones de escritorio vía snap |
| `flatpak`    | flatpak + remoto flathub |

Módulo opcional, **fuera** de la ejecución por defecto:

| Módulo   | Qué hace |
|----------|----------|
| `docker` | Sustituye el docker de la distro por Docker CE del repo oficial. Elimina `docker.io`/`containerd` y para los contenedores en marcha, así que pide confirmación. Solo tiene sentido si la versión de la distro se queda atrás. |

Todos los módulos son idempotentes: se pueden volver a ejecutar sin romper nada.
`~/.zshrc` se respalda automáticamente antes de sobrescribirlo.

## Estructura

```
.zshrc                      configuración del shell (aliases, opciones, integraciones)
zsh/functions/ui.zsh        imprimir_linea / centrar_texto / seccion
zsh/functions/actualizar.zsh  la función `actualizar`
zsh/functions/tools.zsh     ntfy, mkt, checkip, extractPorts, ssht, sshta
zsh/plugins/                autosuggestions, syntax-highlighting, sudo, chuck
apps/kitty/                 kitty.conf, color.ini, tar_bar.py
fonts/                      Hack Nerd Font
```

Las funciones se instalan en `~/.config/zsh/functions` y el `.zshrc` carga todo
lo que haya ahí, así que añadir una función nueva es dejar un `.zsh` en esa
carpeta del repo.

## Atajos de kitty

| Tecla | Acción |
|-------|--------|
| `F1` / `F2` | copiar / pegar del portapapeles |
| `F3` / `F4` | copiar / pegar del buffer `b` |
| `F5` | volcar la salida del último comando en un panel nuevo |
| `ctrl+F1`…`ctrl+F5` | envía las F1–F5 reales a la aplicación |
| `ctrl+shift+o` | abrir URL con hints |
| `ctrl+shift+z` | alternar layout `stack` |

## Mantenimiento

Una vez instalado, la función `actualizar` mantiene el sistema al día: apt,
snap, flatpak, firmware (`fwupd`), pipx, extensiones de `gh`, binarios de cargo,
kitty, Powerlevel10k, los CLIs de IA y el AppImage de Trezor Suite (con
verificación GPG + SHA-512).

## CI

`.github/workflows/lint.yml` pasa `shellcheck` sobre los scripts bash, `zsh -n`
sobre el `.zshrc` y las funciones, y ejecuta `./install.sh --dry-run`.

## Nota

El script modifica la configuración del sistema (shell por defecto, paquetes,
`/usr/share/zsh`). Úsalo bajo tu propia responsabilidad.
