#!/usr/bin/env bash

report_sshd_configuration() {
  local configuration="$1"
  local key value
  local permit_root_login=""
  local password_authentication=""
  local permit_empty_passwords=""
  local protocol=""
  local max_auth_tries=""

  while read -r key value _; do
    case "$key" in
      permitrootlogin) permit_root_login="$value" ;;
      passwordauthentication) password_authentication="$value" ;;
      permitemptypasswords) permit_empty_passwords="$value" ;;
      protocol) protocol="$value" ;;
      maxauthtries) max_auth_tries="$value" ;;
    esac
  done <<< "$configuration"

  case "$permit_root_login" in
    no)
      add_finding ssh info "Root login disabled" \
        "OpenSSH does not permit direct root login."
      ;;
    prohibit-password|without-password|forced-commands-only)
      add_finding ssh info "Root login restricted" \
        "OpenSSH restricts direct root login with the $(sanitize_text "$permit_root_login") policy."
      ;;
    yes)
      add_finding ssh critical "Root login enabled" \
        "OpenSSH permits direct root login." \
        "Disable direct root login and use an accountable administrative path."
      ;;
    *)
      add_finding ssh info "Root login policy unavailable" \
        "The evaluated PermitRootLogin value was not reported."
      ;;
  esac

  case "$password_authentication" in
    no)
      add_finding ssh info "Password authentication disabled" \
        "OpenSSH password authentication is disabled."
      ;;
    yes)
      add_finding ssh warning "Password authentication enabled" \
        "OpenSSH password authentication is enabled." \
        "Prefer key-based or centrally managed authentication where appropriate."
      ;;
    *)
      add_finding ssh info "Password authentication policy unavailable" \
        "The evaluated PasswordAuthentication value was not reported."
      ;;
  esac

  case "$permit_empty_passwords" in
    no)
      add_finding ssh info "Empty passwords rejected" \
        "OpenSSH rejects empty passwords."
      ;;
    yes)
      add_finding ssh critical "Empty passwords permitted" \
        "OpenSSH permits accounts with empty passwords to authenticate." \
        "Set PermitEmptyPasswords to no."
      ;;
    *)
      add_finding ssh info "Empty-password policy unavailable" \
        "The evaluated PermitEmptyPasswords value was not reported."
      ;;
  esac

  if [[ -n "$protocol" ]]; then
    if [[ ",$protocol," == *,1,* || "$protocol" == "1" ]]; then
      add_finding ssh critical "Legacy SSH protocol enabled" \
        "The evaluated configuration enables SSH protocol version 1." \
        "Allow only SSH protocol version 2."
    else
      add_finding ssh info "SSH protocol" \
        "The evaluated SSH protocol setting is $(sanitize_text "$protocol")."
    fi
  fi

  if is_unsigned_integer "$max_auth_tries"; then
    if (( max_auth_tries > 6 )); then
      add_finding ssh warning "High authentication attempt limit" \
        "MaxAuthTries is set to $max_auth_tries." \
        "Reduce MaxAuthTries to limit repeated authentication attempts."
    else
      add_finding ssh info "Authentication attempt limit" \
        "MaxAuthTries is set to $max_auth_tries."
    fi
  else
    add_finding ssh info "Authentication attempt limit unavailable" \
      "The evaluated MaxAuthTries value was not reported."
  fi
}

run_ssh_check() {
  if ! command_exists sshd; then
    add_finding ssh info "OpenSSH server unavailable" \
      "The sshd command is not available; server configuration was not evaluated."
    return 0
  fi

  if capture_command sshd -T; then
    report_sshd_configuration "$COMMAND_OUTPUT"
  else
    add_finding ssh info "OpenSSH configuration unavailable" \
      "sshd could not evaluate the server configuration." \
      "Review configuration readability, host keys, and sshd diagnostics manually."
  fi
}
