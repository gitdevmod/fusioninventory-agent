package FusionInventory::Agent::Task::Inventory::Win32::Chassis;

use strict;
use warnings;

use FusionInventory::Agent::Tools::Win32;

my @chassisType = (
    'Unknown',
    'Other',
    'Unknown',
    'Desktop',
    'Low Profile Desktop',
    'Pizza Box',
    'Mini Tower',
    'Tower',
    'Portable',
    'Laptop',
    'Notebook',
    'Hand Held',
    'Docking Station',
    'All in One',
    'Sub Notebook',
    'Space-Saving',
    'Lunch Box',
    'Main System Chassis',
    'Expansion Chassis',
    'SubChassis',
    'Bus Expansion Chassis',
    'Peripheral Chassis',
    'Storage Chassis',
    'Rack Mount Chassis',
    'Sealed-Case PC'
);

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    $inventory->setHardware({
        CHASSIS_TYPE => _getChassis(logger => $params{logger})
    });
}

sub _getChassis {
    my (%params) = @_;

    my $chassis;

    foreach my $object (getWMIObjects(
        class      => 'Win32_SystemEnclosure',
        properties => [ qw/ChassisTypes/ ]
    )) {
        $chassis = $chassisType[$object->{ChassisTypes}->[0]];
    }

    return $chassis;
}

1;
