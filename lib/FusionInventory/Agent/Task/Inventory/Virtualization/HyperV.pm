package FusionInventory::Agent::Task::Inventory::Virtualization::HyperV;

use strict;
use warnings;

use English qw(-no_match_vars);
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;
use FusionInventory::Agent::Tools::Virtualization;

sub isEnabled {
    return $OSNAME eq 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $machine (_getVirtualMachines(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIRTUALMACHINES', entry => $machine
        );
    }
}

sub _getVirtualMachines {
    FusionInventory::Agent::Tools::Win32->require();

    my $hostname = getHostname(short => 1);

    my @machines;

    # index memory, cpu and BIOS UUID information
    my %memory;
    foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_MemorySettingData',
        properties => [ qw/InstanceID VirtualQuantity/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $id =~ /^Microsoft:([^\\]+)/;
        $memory{$1} = $object->{VirtualQuantity};
    }

    my %vcpu;
    foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_ProcessorSettingData',
        properties => [ qw/InstanceID VirtualQuantity/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $id =~ /^Microsoft:([^\\]+)/;
        $vcpu{$1} = $object->{VirtualQuantity};
    }

    my %biosguid;
    foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_VirtualSystemSettingData',
        properties => [ qw/InstanceID BIOSGUID/ ]
    )) {
        my $id = $object->{InstanceID};
        next unless $object->{BIOSGUID} && $id =~ /^Microsoft:([^\\]+)/;
        $biosguid{$1} = $object->{BIOSGUID};
        $biosguid{$1} =~ tr/{}//d;
    }

    foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
        moniker    => 'winmgmts://./root/virtualization/v2',
        altmoniker => 'winmgmts://./root/virtualization',
        class      => 'MSVM_ComputerSystem',
        properties => [ qw/ElementName EnabledState Name/ ]
    )) {
        # skip host
        next if lc($object->{Name}) eq lc($hostname);

        my $status =
            $object->{EnabledState} == 2     ? STATUS_RUNNING  :
            $object->{EnabledState} == 3     ? STATUS_OFF      :
            $object->{EnabledState} == 32768 ? STATUS_PAUSED   :
            $object->{EnabledState} == 32769 ? STATUS_OFF      :
            $object->{EnabledState} == 32770 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32771 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32773 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32774 ? STATUS_SHUTDOWN :
            $object->{EnabledState} == 32776 ? STATUS_BLOCKED  :
            $object->{EnabledState} == 32777 ? STATUS_BLOCKED  :
                                               STATUS_OFF      ;
        my $machine = {
            SUBSYSTEM => 'MS HyperV',
            VMTYPE    => 'HyperV',
            STATUS    => $status,
            NAME      => $object->{ElementName},
            UUID      => $biosguid{$object->{Name}},
            MEMORY    => $memory{$object->{Name}},
            VCPU      => $vcpu{$object->{Name}},
        };

        push @machines, $machine;

    }

    return @machines;
}

1;
