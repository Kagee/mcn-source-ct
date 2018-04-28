#! /bin/bash
SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# This way we can work with realtive paths in the rest of the script
cd "${SOURCE_DIR}"

source config.sh

# PYTHON_CT="$CT_PATH/certificate-transparency/python"
LOG_CLIENT="${PYTHON_CT}/ct/client/log_client.py"

if [ -f "${LOG_CLIENT}.orig" ]; then
    echo "[INFO] Found ${LOG_CLIENT}.orig, already patched";
else
    cp "${LOG_CLIENT}" "${LOG_CLIENT}.orig";
    sed -i -e 's/verify=self._ca_bundle)/verify=False)/g' "$LOG_CLIENT";
    echo "[INFO] Backup made (${LOG_CLIENT}.orig), patch applied"
fi


WHY_WE_DO_THIS=<<EOF
The scanner has no interface to send verify=False or a string to a  
CA bundle, so we patch log_client.py.

Some strings to grep for:

scanner.scan_log:
    bound_scan = functools.partial(_scan, entry_queue, log_url)
    res = scanners_pool.map_async(bound_scan, scan_range,
                                  callback=stop_workers_callback)

log_client.py:                                    verify=self._ca_bundle)

class RequestHandler(object):
    """HTTPS requests."""
    def __init__(self, connection_timeout=60, ca_bundle=True, num_retries=None):


class LogClient(object):
    def __init__(self, uri, handler=None, connection_timeout=60,
                 ca_bundle=True):
        self._uri = uri
        if not ca_bundle:
          raise ClientError("Refusing to turn off SSL certificate checking.")

          self._request_handler = RequestHandler(connection_timeout, ca_bundle)


verify -- (optional) Either a boolean, in which case it controls 
whether we verify the server's TLS certificate, or a string, in 
which case it must be a path to a CA bundle to use. Defaults to True.

EOF

