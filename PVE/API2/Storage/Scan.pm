package PVE::API2::Storage::Scan;

use strict;
use warnings;

use PVE::SafeSyslog;
use PVE::Storage;
use HTTP::Status qw(:constants);
use PVE::JSONSchema qw(get_standard_option);

use PVE::RESTHandler;

use base qw(PVE::RESTHandler);

__PACKAGE__->register_method ({
    name => 'index', 
    path => '', 
    method => 'GET',
    description => "Index of available scan methods",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => { method => { type => 'string'} },
	},
	links => [ { rel => 'child', href => "{method}" } ],
    },
    code => sub {
	my ($param) = @_;

	my $res = [ 
	    { method => 'lvm' },
	    { method => 'iscsi' },
	    { method => 'nfs' },
	    { method => 'usb' },
	    ];

	return $res;
    }});

__PACKAGE__->register_method ({
    name => 'nfsscan', 
    path => 'nfs', 
    method => 'GET',
    description => "Scan remote NFS server.",
    protected => 1,
    proxyto => "node",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	    server => { type => 'string', format => 'pve-storage-server' },
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => { 
		path => { type => 'string'},
		options => { type => 'string'},
	    },
	},
    },
    code => sub {
	my ($param) = @_;

	my $server = $param->{server};
	my $res = PVE::Storage::scan_nfs($server);

	my $data = [];
	foreach my $k (keys %$res) {
	    push @$data, { path => $k, options => $res->{$k} };
	}
	return $data;
    }});

__PACKAGE__->register_method ({
    name => 'iscsiscan', 
    path => 'iscsi', 
    method => 'GET',
    description => "Scan remote iSCSI server.",
    protected => 1,
    proxyto => "node",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	    portal => { type => 'string', format => 'pve-storage-portal-dns' },
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => { 
		target => { type => 'string'},
		portal => { type => 'string'},
	    },
	},
    },
    code => sub {
	my ($param) = @_;

	my $res = PVE::Storage::scan_iscsi($param->{portal});

	my $data = [];
	foreach my $k (keys %$res) {
	    push @$data, { target => $k, portal => join(',', @{$res->{$k}}) };
	}

	return $data;
    }});

__PACKAGE__->register_method ({
    name => 'lvmscan', 
    path => 'lvm', 
    method => 'GET',
    description => "List local LVM volume groups.",
    protected => 1,
    proxyto => "node",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => { 
		vg => { type => 'string'},
	    },
	},
    },
    code => sub {
	my ($param) = @_;

	my $res = PVE::Storage::lvm_vgs();
	return PVE::RESTHandler::hash_to_array($res, 'vg');
    }});

__PACKAGE__->register_method ({
    name => 'usbscan', 
    path => 'usb', 
    method => 'GET',
    description => "List local USB devices.",
    protected => 1,
    proxyto => "node",
    parameters => {
    	additionalProperties => 0,
	properties => {
	    node => get_standard_option('pve-node'),
	},
    },
    returns => {
	type => 'array',
	items => {
	    type => "object",
	    properties => { 
		busnum => { type => 'integer'},
		devnum => { type => 'integer'},
		port => { type => 'integer'},
		usbpath => { type => 'string', optional => 1},
		level => { type => 'integer'},
		class => { type => 'integer'},
		vendid => { type => 'string'},
		prodid => { type => 'string'},
		speed => { type => 'string'},

		product => { type => 'string', optional => 1 },
		serial => { type => 'string', optional => 1 },
		manufacturer => { type => 'string', optional => 1 },
	    },
	},
    },
    code => sub {
	my ($param) = @_;

	return PVE::Storage::scan_usb();
    }});

1;
