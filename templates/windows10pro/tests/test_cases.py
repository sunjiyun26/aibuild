#!/usr/bin/env python
# -*- coding: utf-8 -*-

import libvirt
import math
import time
import os
import random
import shutil
import string
import sys
import re
import xml.etree.ElementTree as et
from xml.etree.ElementTree import Element as element
import winrm


DEFAULT_SYSDISK_SIZE = 80
WAIT_VM_OK_TIME = 600 # second
TOLERANCE = 1024 * 1024 * 1024 * 5

DEFAULTT_SERVER_BOOT_TIMEOUT = 60

DEFAULT_SSH_USER = 'root'
DEFAULT_SSH_PASSWORD = 'Lc13yfwpW'

TEST_DIR = '/tmp/'


def toIPAddrType(addrType):
    if addrType == libvirt.VIR_IP_ADDR_TYPE_IPV4:
        return "ipv4"
    elif addrType == libvirt.VIR_IP_ADDR_TYPE_IPV6:
        return "ipv6"


def get_addr(dom_name):
    conn = libvirt.open('qemu:///system')
    dom = conn.lookupByName(dom_name)
    ifaces = dom.interfaceAddresses(libvirt.VIR_DOMAIN_INTERFACE_ADDRESSES_SRC_LEASE)
    # Only one interface
    for (name, val) in ifaces.iteritems():
        if val['addrs']:
            for addr in val['addrs']:
                conn.close()
                return addr['addr']

    conn.close()


def get_winrm_connection(ip="localhost", port="5985", username="administrator", password="Lc13yfwpW", **kwargs):
    """
    obtain winrm connection
    :param ip: virtual machine ip
    :param port:
    :param username:
    :param password:
    :return:
    """
    session = winrm.Session("%s:%s" % (ip, port), auth=(username, password))
    return session


def _output_log_to_file(conn, dom, log_file_path='/var/log/sjt-test.log'):
    """
    modify domain XML and append logs to files
    :param conn
    :param dom:
    :param log_file_path: log file path
    :return:
    """

    dom_xml = dom.XMLDesc()

    root = et.fromstring(dom_xml)
    device = root.find('devices')

    serials = root.findall('*/serial')
    for serial in serials:
        device.remove(serial)

    consoles = root.findall('*/console')
    for console in consoles:
        serial_log_node = element('log')
        serial_log_node.set('file', log_file_path)
        serial_log_node.set('append', 'off')
        console.insert(-1, serial_log_node)

    new_dom_xml = et.tostring(root)

    dom.undefine()
    dom.defineXML(new_dom_xml)

    return dom


def clean_up(dom_name, tmp_path):
    # Destroy dom
    conn = libvirt.open('qemu:///system')
    dom = conn.lookupByName(dom_name)
    dom.destroy()
    dom.undefine()
    conn.close()

    # Remove tmp path
    shutil.rmtree(tmp_path)


class TestBase(object):
    """
    fixme give it a better name
    TestBase is used to set up environment for all the following tests
    """

    def __init__(self, domain_name, image):
        self.conn = None
        self.image = image
        self.dom = None
        self.tmp_path = None
        self.domain_name = domain_name

    def clean_up(self):
        """
        clean up temp folder & backup image files
        :return:
        """
        clean_up(self.domain_name, self.tmp_path)

    def __enter__(self):
        self.create_domain()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.clean_up()

    def create_domain(self):
        """
        create(define) a new domain
        :param image:
        :param domain_name:
        :return:
        """

        domain_name = self.domain_name
        image = self.image

        # create a temp folder
        ran_str = ''.join(random.sample(string.ascii_letters, 8))
        tmp_path = TEST_DIR + ran_str
        self.tmp_path = tmp_path
        os.mkdir(tmp_path)
        shutil.copy(image, tmp_path)

        # copy and backup tested image
        os.chdir(TEST_DIR + ran_str)
        img_file = os.path.split(sys.argv[1])[-1]

        # resize drive to DEFAULT_SYSDISK_SIZE
        os.system('qemu-img resize ' + img_file + ' +' + (DEFAULT_SYSDISK_SIZE - 40) + 'G')

        # I have not been able to think of an esaier solution to this
        # libvirt python library requires XML to define a domain
        # better learn how nova handles this
        cmd_create = 'virt-install --name ' + domain_name + ' --disk path=' + img_file + \
                     ',bus=virtio,cache=none --network network=default,model=virtio' \
                     ' --ram 8192  --vcpus 4 --accelerate --boot hd ' \
                     ' --console pty,target_type=serial ' \
                     '--vnc --vnclisten 0.0.0.0 --noreboot --autostart --import'
        os.system(cmd_create)

    def _lookup_domain_by_name(self):

        domain_name = self.domain_name
        if not self.conn:
            self._initialize_connection()

        dom = self.conn.lookupByName(domain_name)
        if not dom:
            print "Failed finding domain with name %s" % domain_name
            raise Exception("Failed finding domain with name %s" % domain_name)
        return dom

    def _initialize_connection(self):

        if not self.conn:
            self.conn = libvirt.open(None)
            if not self.conn:
                print "Failed connecting local libvirt daemon!"
                raise Exception('Failed connecting local libvirt daemon!')

    def update_domain(self):
        """
        update a domain (better inactive)
        by default, add log
        :param domain_name:
        :return:
        """

        domain_name = self.domain_name
        if not domain_name:
            return

        dom = self._lookup_domain_by_name(domain_name)
        self.dom = _output_log_to_file(self.conn, dom)

    def start_domain(self, updatable=True):
        """
        running an inactive domain
        :param updatable: if one wants to domain should be updated before launching
        :return:
        """
        domain_name = self.domain_name
        if updatable:
            self.update_domain(domain_name)
        dom = self._lookup_domain_by_name(domain_name)

        # this method is synchronous by nature
        # but in a specific test case, one should
        # wait for os bootup to continue further operations
        dom.create()

        # waiting for a specific period of time
        time.sleep(DEFAULTT_SERVER_BOOT_TIMEOUT)

    def run_test(self, **kwargs):
        pass


class TestStub(object):

    TEST_NAME = None

    def run_test(self, **kwargs):
        pass


class TestCaseValidateDiskExtend(TestStub):

    TEST_NAME = "Test Disk Resize"

    def run_test(self, **kwargs):
        ps_script = """
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        echo $disk.size
        """

        s = get_winrm_connection(**kwargs)
        r = s.run_ps(ps_script)

        if r.status_code == 0:
            # fixme set initial size default to 40G
            size = int(kwargs.get('size', DEFAULT_SYSDISK_SIZE)) * 1024 * 1024 * 1024
            real_size = int(r.std_out)

            if math.fabs(size - real_size) < TOLERANCE:
                return True
            else:
                raise Exception("Drive Size does not grow expectively, make sure cloudbase-init correctly installed")
        else:
            print "Failed Executing Powershell Script"
            raise Exception(r.std_err)


class TestOsEdition(TestStub):
    """
    verify operating system edition
    using `systeminfo` command
    """

    OS_EDITION = u"Windows 10"
    TEST_NAME = "Test OS Edition"

    def run_test(self, **kwargs):
        s = get_winrm_connection(**kwargs)
        r = s.run_cmd('systeminfo')

        if r.status_code == 0:
            out = r.std_out.split(r"\r\n")
            for line in out:
                if re.search(u"OS NAME|OS 名称", line, re.IGNORECASE):
                    os_edition = TestOsEdition.OS_EDITION
                    if not os_edition:
                        if re.search(os_edition, line, re.IGNORECASE):
                            return True
            else:
                # cannot find target edition
                raise  Exception("OS Edition Information Cannot Be Found")
        else:
            print("Test failed %d, %s", r.status_code, r.std_err)
            raise Exception(r.std_err)


def main():
    if len(sys.argv) < 2 or not os.path.exists(sys.argv[1]):
        print("Please input image to be verified!")
        exit(1)

    domain_name = sys.argv[0]
    image_file = sys.argv[1]

    try:
        with TestBase(domain_name, image_file) as stub:

            kwargs = {}

            # waiting for ip initialization
            times = 3
            while times >= 0:
                ip = get_addr(stub.domain_name)
                kwargs.update({"ip": ip})
                if ip:
                    break
                time.sleep(60)
                times -= 1

            for test_class in TestStub.__subclasses__():
                print "%s is running" % test_class.TEST_NAME
                ret = test_class().run_test(**kwargs)
                if ret:
                    print "%s finishes correctly" % test_class.TEST_NAME
                else:
                    print "%s does not work" % test_class.TEST_NAME
                    return 1
    except Exception as e:
        print (e)
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())