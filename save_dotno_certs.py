#!/usr/bin/env python
# Based on /ct/certificate-transparency/python/ct/client/tools/simple_scan.py
import requests

requests.packages.urllib3.disable_warnings()


import os
import sys

from absl import flags as gflags

from ct.client import scanner
from ct.crypto.cert import CertificateError

FLAGS = gflags.FLAGS

gflags.DEFINE_integer(
    "multi", 2,
    "Number of cert parsing processes to use in addition to the main process and the network process."
)
gflags.DEFINE_integer("startat", 0,
                      "What certificate index to start at. (default 0)")
gflags.DEFINE_string("output", None,
                     "Output directory to write certificates to.")
gflags.DEFINE_string("log", None, "URL of log to scan")
gflags.DEFINE_boolean("secure", False,
                      "Wether or not to verify HTTPS");

def match(certificate, entry_type, extra_data, certificate_index):
    try:
        # Check certificate subject names of type DNS for entries
        # that end in ".no"
        for sdn in certificate.subject_dns_names():
            if sdn.human_readable().endswith('.no'):
                # Return name and matching certificate as DER
                return ("cert_%d.der" % certificate_index,
                        certificate.to_der())
    except (CertificateError):
        # Ignore CertificateErrors
        pass


def write_matched_certificate(matcher_output):
    output_file, der_data = matcher_output
    with open(os.path.join(FLAGS.output, output_file), "wb") as f:
        f.write(der_data)


def run():
    if not FLAGS.output:
        raise Exception("Certificates output directory must be specified.")
    if not os.path.exists(FLAGS.output):
        # Create output folder is is does not exist
        os.makedirs(FLAGS.output)

    if not FLAGS.log:
        raise Exception("Log to scan must be specified.")

    res = scanner.scan_log(match, FLAGS.log, FLAGS.multi,
                           write_matched_certificate, FLAGS.startat)

    print "Scanned %d, %d matched and %d failed strict or partial parsing" % (
        res.total, res.matches, res.errors)


if __name__ == "__main__":
    sys.argv = FLAGS(sys.argv)
    run()
