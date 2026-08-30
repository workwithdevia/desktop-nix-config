{
  pkgs,
  lib,
  ...
}: let
  waydroidUser = "workwithdevia";
  waydroidUid = 1000;

  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      requests
      inquirerpy
      tqdm
    ]);

  xuperApk = ./apks/Xuper.Hydra4KHDRMachoMiller.apk;
  xuperPackage = "com.xuper.netxxus";

  installMarker = "/var/lib/waydroid/.xuper-installed";
in {
  # ============================================================
  # Kernel
  # ============================================================

  boot.kernelModules = [
    "ip_tables"
    "iptable_filter"
    "iptable_nat"
    "iptable_mangle"
  ];

  boot.kernelPackages = pkgs.linuxPackages;

  # ============================================================
  # Network
  # ============================================================

  networking.firewall.trustedInterfaces = [
    "waydroid0"
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [
      "waydroid0"
    ];
    externalInterface = "enp1s0";
  };

  # ============================================================
  # Waydroid
  # ============================================================

  virtualisation.waydroid.enable = true;

  # ------------------------------------------------------------
  # IMPORTANTE:
  # Waydroid NO se inicia automáticamente al arrancar NixOS.
  # Solo nuestro bootstrap lo levanta cuando sea necesario.
  # ------------------------------------------------------------

  systemd.services.waydroid-container.wantedBy =
    lib.mkForce [];

  # ============================================================
  # Sudo
  # ============================================================

  security.sudo.extraRules = [
    {
      users = [
        waydroidUser
      ];

      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start waydroid-container.service";
          options = [
            "NOPASSWD"
          ];
        }

        {
          command = "/run/current-system/sw/bin/systemctl stop waydroid-container.service";
          options = [
            "NOPASSWD"
          ];
        }
      ];
    }
  ];

  # ============================================================
  # Bootstrap de Waydroid
  # ============================================================

  systemd.services.init-waydroid = {
    description = "Inicialización única de Waydroid + libhoudini + Xuper";

    wantedBy = [
      "multi-user.target"
    ];

    wants = [
      "network-online.target"
    ];

    after = [
      "network-online.target"
    ];

    # ----------------------------------------------------------
    # SOLO ejecutar si Xuper todavía no fue instalada correctamente
    # ----------------------------------------------------------

    unitConfig = {
      ConditionPathExists = "!${installMarker}";
    };

    path = with pkgs; [
      bash
      coreutils
      findutils
      gawk
      git
      gnugrep
      procps
      util-linux
      waydroid
      pythonEnv
    ];

    serviceConfig = {
      Type = "oneshot";

      # Importante: esto mantiene el estado "active"
      # después de una ejecución exitosa.
      RemainAfterExit = true;

      TimeoutStartSec = "45min";
    };

    script = ''
            set -euo pipefail

            # ==========================================================
            # Variables
            # ==========================================================

            APK="${xuperApk}"
            PACKAGE="${xuperPackage}"

            RUNTIME_DIR="/run/user/${toString waydroidUid}"
            DBUS_BUS="unix:path=$RUNTIME_DIR/bus"

            PYTHON="${pythonEnv.interpreter}"

            WAYDROID_SCRIPT="/var/lib/waydroid/waydroid_script"

            SESSION_LOG="/var/lib/waydroid/session-start.log"
            INSTALL_LOG="/var/lib/waydroid/xuper-install.log"

            # ==========================================================
            # Ejecutar comandos como workwithdevia
            # ==========================================================

            waydroid_user() {
              runuser -u "${waydroidUser}" -- \
                env \
                  HOME="/home/${waydroidUser}" \
                  XDG_RUNTIME_DIR="$RUNTIME_DIR" \
                  DBUS_SESSION_BUS_ADDRESS="$DBUS_BUS" \
                  "$@"
            }

            # ==========================================================
            # Ejecutar operaciones administrativas como root,
            # conservando el D-Bus de la sesión de workwithdevia.
            # ==========================================================

            waydroid_root() {
              env \
                HOME="/root" \
                XDG_RUNTIME_DIR="$RUNTIME_DIR" \
                DBUS_SESSION_BUS_ADDRESS="$DBUS_BUS" \
                "$@"
            }

            # ==========================================================
            # Estado
            # ==========================================================

            get_status() {
              waydroid_user waydroid status 2>/dev/null || true
            }

            # ==========================================================
            # Asegurar que Container esté RUNNING
            # ==========================================================

            ensure_container_running() {
              local status

              status="$(get_status)"
              status="$(printf '%s\n' "$status" | tr -d '\r')"

              if printf '%s\n' "$status" |
                grep -Eq '^Container:[[:space:]]+RUNNING[[:space:]]*$'; then
                return 0
              fi

              if printf '%s\n' "$status" |
                grep -Eq '^Container:[[:space:]]+FROZEN[[:space:]]*$'; then

                echo "==> Container FROZEN -> unfreeze"

                waydroid_root \
                  waydroid container unfreeze || true

                sleep 2

                status="$(get_status)"
                status="$(printf '%s\n' "$status" | tr -d '\r')"

                if printf '%s\n' "$status" |
                  grep -Eq '^Container:[[:space:]]+RUNNING[[:space:]]*$'; then
                  return 0
                fi
              fi

              echo "==> Container no RUNNING -> restart"

              waydroid_root \
                waydroid container restart || true

              sleep 3

              status="$(get_status)"
              status="$(printf '%s\n' "$status" | tr -d '\r')"

              if printf '%s\n' "$status" |
                grep -Eq '^Container:[[:space:]]+RUNNING[[:space:]]*$'; then
                return 0
              fi

              echo "ERROR: Container no pudo llegar a RUNNING."
              echo "$status"

              return 1
            }

            # ==========================================================
            # INICIO
            # ==========================================================

            echo "=============================================="
            echo " Inicialización única de Waydroid"
            echo "=============================================="

            # ==========================================================
            # 1. APK
            # ==========================================================

            if [ ! -f "$APK" ]; then
              echo "ERROR: No existe la APK:"
              echo "$APK"
              exit 1
            fi

            echo "==> APK:"
            echo "$APK"

            # ==========================================================
            # 2. Waydroid init
            # ==========================================================

            if [ ! -d "/var/lib/waydroid/cells" ]; then

              echo "==> Waydroid no está inicializado."
              echo "==> Ejecutando waydroid init..."

              waydroid init \
                -f \
                -c "https://ota.waydro.id/system" \
                -v "https://ota.waydro.id/vendor"

              echo "==> Waydroid inicializado."

            else

              echo "==> Waydroid ya está inicializado."

            fi

            # ==========================================================
            # 3. waydroid_script
            # ==========================================================

            if [ ! -d "$WAYDROID_SCRIPT" ]; then

              echo "==> Clonando waydroid_script..."

              mkdir -p /var/lib/waydroid

              git clone \
                "https://github.com/casualsnek/waydroid_script.git" \
                "$WAYDROID_SCRIPT"

            else

              echo "==> waydroid_script ya existe."

            fi

            cd "$WAYDROID_SCRIPT"

            # ==========================================================
            # 4. Python
            # ==========================================================

            echo "==> Python:"
            "$PYTHON" --version

            echo "==> Comprobando InquirerPy..."

            "$PYTHON" -c \
              'from InquirerPy import inquirer; print("InquirerPy OK")'

            # ==========================================================
            # 5. libhoudini
            # ==========================================================

            echo "==> Instalando/actualizando libhoudini..."

            "$PYTHON" main.py install libhoudini

            echo "==> libhoudini instalado correctamente."

            # ==========================================================
            # 6. Configuración
            # ==========================================================

            echo "==> Configurando Waydroid..."

            waydroid prop set qemu.hw.mainkeys 1

            # ==========================================================
            # 7. Runtime usuario
            # ==========================================================

            if [ ! -d "$RUNTIME_DIR" ]; then
              echo "ERROR: No existe:"
              echo "$RUNTIME_DIR"
              exit 1
            fi

            if [ ! -S "$RUNTIME_DIR/bus" ]; then
              echo "ERROR: No existe:"
              echo "$RUNTIME_DIR/bus"
              exit 1
            fi

            # ==========================================================
            # 8. Arrancar container
            # ==========================================================

            echo "==> Iniciando contenedor..."

            systemctl start waydroid-container.service

            sleep 2

            # ==========================================================
            # 9. Arrancar sesión
            # ==========================================================

            STATUS="$(get_status)"
            STATUS="$(printf '%s\n' "$STATUS" | tr -d '\r')"

            if ! printf '%s\n' "$STATUS" |
              grep -Eq '^Session:[[:space:]]+RUNNING[[:space:]]*$'; then

              echo "==> Iniciando sesión Waydroid..."

              : > "$SESSION_LOG"

              waydroid_user \
                nohup waydroid session start \
                > "$SESSION_LOG" 2>&1 &

            else

              echo "==> Sesión ya RUNNING."

            fi

            # ==========================================================
            # 10. Esperar Waydroid RUNNING
            # ==========================================================

            echo "==> Esperando Session + Container..."

            READY=0

            for i in $(seq 1 90); do

              STATUS="$(get_status)"
              STATUS="$(printf '%s\n' "$STATUS" | tr -d '\r')"

              echo "[$i/90]"
              printf '%s\n' "$STATUS"

              if printf '%s\n' "$STATUS" |
                grep -Eq '^Container:[[:space:]]+FROZEN[[:space:]]*$'; then

                echo "==> Container FROZEN -> unfreeze"

                waydroid_root \
                  waydroid container unfreeze || true

                sleep 2

                continue
              fi

              if printf '%s\n' "$STATUS" |
                grep -Eq '^Session:[[:space:]]+RUNNING[[:space:]]*$' &&
                 printf '%s\n' "$STATUS" |
                grep -Eq '^Container:[[:space:]]+RUNNING[[:space:]]*$'; then

                echo "==> Session RUNNING."
                echo "==> Container RUNNING."

                READY=1

                break
              fi

              sleep 2
            done

            if [ "$READY" -ne 1 ]; then

              echo "ERROR: Waydroid no llegó a RUNNING."

              get_status || true

              echo "==> Log de sesión:"
              cat "$SESSION_LOG" 2>/dev/null || true

              exit 1
            fi

            # ==========================================================
            # 11. Esperar Android shell
            # ==========================================================

            echo "==> Esperando Android shell..."

            SHELL_READY=0

            for i in $(seq 1 60); do

              if waydroid_root \
                waydroid shell true >/dev/null 2>&1; then

                SHELL_READY=1
                break
              fi

              ensure_container_running || true

              echo "[$i/60] Android shell no disponible..."

              sleep 2
            done

            if [ "$SHELL_READY" -ne 1 ]; then

              echo "ERROR: Android shell no está disponible."

              get_status || true

              exit 1
            fi

            echo "==> Android shell disponible."

            # ==========================================================
            # 12. PackageManager
            # ==========================================================

            echo "==> Esperando PackageManager..."

            PM_READY=0

            for i in $(seq 1 30); do

              if waydroid_root \
                waydroid shell pm list packages >/dev/null 2>&1; then

                PM_READY=1
                break
              fi

              ensure_container_running || true

              echo "[$i/30] PackageManager no disponible..."

              sleep 2
            done

            if [ "$PM_READY" -ne 1 ]; then

              echo "ERROR: PackageManager no está disponible."

              exit 1
            fi

            echo "==> PackageManager disponible."

            # ==========================================================
            # 13. Comprobar Xuper
            # ==========================================================

            echo "==> Comprobando $PACKAGE..."

            PACKAGE_PATH="$(
              waydroid_root \
                waydroid shell pm path "$PACKAGE" 2>/dev/null |
              grep '^package:' |
              head -n 1 ||
              true
            )"

            if [ -n "$PACKAGE_PATH" ]; then

              case "$PACKAGE_PATH" in

                package:/data/*)

                  echo "==> Xuper ya está instalada:"
                  echo "$PACKAGE_PATH"

                  ;;

                package:/system/*)

                  echo "ERROR: Xuper está instalada como SYSTEM APP."
                  echo "$PACKAGE_PATH"

                  exit 1

                  ;;

                *)

                  echo "ERROR: Ruta inesperada:"
                  echo "$PACKAGE_PATH"

                  exit 1

                  ;;
              esac

            else

              # ========================================================
              # 14. INSTALAR XUPER
              # ========================================================

              echo "==> Xuper no está instalada."
              echo "==> Instalando como ${waydroidUser}..."

              rm -f "$INSTALL_LOG"

              if ! waydroid_user \
                waydroid app install "$APK" \
                >"$INSTALL_LOG" 2>&1; then

                echo "ERROR: waydroid app install falló."

                cat "$INSTALL_LOG"

                exit 1
              fi

              echo "==> Instalación terminada."

              cat "$INSTALL_LOG"

            fi

            # ==========================================================
            # 15. Verificación final
            # ==========================================================

            echo "==> Verificación final..."

            PACKAGE_PATH="$(
              waydroid_root \
                waydroid shell pm path "$PACKAGE" 2>/dev/null |
              grep '^package:' |
              head -n 1 ||
              true
            )"

            if [ -z "$PACKAGE_PATH" ]; then

              echo "ERROR: Android no registra:"
              echo "$PACKAGE"

              echo "==> Diagnóstico:"

              waydroid_root \
                waydroid shell dumpsys package "$PACKAGE" \
                2>/dev/null ||
                true

              exit 1
            fi

            # ==========================================================
            # 16. Confirmar que está en /data
            # ==========================================================

            case "$PACKAGE_PATH" in

              package:/data/*)

                echo "=============================================="
                echo " XUPER INSTALADA CORRECTAMENTE"
                echo "=============================================="
                echo "Paquete : $PACKAGE"
                echo "Ruta    : $PACKAGE_PATH"
                echo "=============================================="

                ;;

              package:/system/*)

                echo "ERROR: Xuper quedó como SYSTEM APP:"
                echo "$PACKAGE_PATH"

                exit 1
                ;;

              *)

                echo "ERROR: Ruta inesperada:"
                echo "$PACKAGE_PATH"

                exit 1
                ;;

            esac

            # ==========================================================
            # 17. MARCAR INSTALACIÓN COMPLETADA
            #
            # Desde este momento init-waydroid NO volverá a ejecutarse
            # automáticamente en futuros arranques.
            # ==========================================================

            echo "==> Marcando instalación completada..."

            mkdir -p /var/lib/waydroid

            cat > "${installMarker}" <<EOF
      package=$PACKAGE
      apk=$APK
      installed=$(date -Iseconds)
      EOF

            chmod 644 "${installMarker}"

            echo "==> Marcador creado:"
            echo "    ${installMarker}"

            # ==========================================================
            # 18. Detener sesión
            # ==========================================================

            echo "==> Deteniendo sesión Waydroid..."

            waydroid_user \
              waydroid session stop \
              || true

            sleep 2

            # ==========================================================
            # 19. Detener container
            # ==========================================================

            echo "==> Deteniendo contenedor..."

            systemctl stop waydroid-container.service

            sleep 2

            echo
            echo "=============================================="
            echo " Bootstrap finalizado"
            echo "=============================================="
            echo " Xuper instalada en /data"
            echo " Waydroid detenido"
            echo " El bootstrap no volverá a ejecutarse"
            echo " automáticamente."
            echo "=============================================="
    '';
  };
}
