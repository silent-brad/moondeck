#!/usr/bin/env nu

# Deploy changed config files to the device and trigger a hot reload.
#
# Usage:
#   nu scripts/deploy.nu <device-ip>            # upload git-changed config files
#   nu scripts/deploy.nu <device-ip> --all      # upload all config files
#   nu scripts/deploy.nu <device-ip> --reload   # just reload, no upload

def main [
  device: string  # Device IP address (shown on display during boot)
  --all           # Upload all config files, not just changed ones
  --reload        # Only trigger reload, skip uploading
] {
  let base_url = $"http://($device)"

  if not $reload {
    let files = if $all {
      glob config/**/*.lua
    } else {
      git diff --name-only HEAD -- config/
        | lines
        | where { ($in | str trim) != "" }
    }

    if ($files | is-empty) {
      print "No config files to upload."
    } else {
      for file in $files {
        let path = $file | str trim
        print $"uploading ($path)"
        http post $"($base_url)/upload?path=($path)" (open --raw $path)
      }
      print $"uploaded ($files | length) file\(s)"
    }

    # Always upload .env so environment variable changes take effect on reload
    if (".env" | path exists) {
      print "uploading .env"
      http post $"($base_url)/upload?path=config/.env" (open --raw .env)
    }
  }

  print "reloading..."
  http post $"($base_url)/reload" ""
  print "done"
}
