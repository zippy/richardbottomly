# a bot to send ETH sale notifications to mattermost via a webhook
# Copyleft 2018 (totally free)
use JSON::Parse 'parse_json';

my $fname = "last.txt";
local $/=undef;
my $start_block = 0;
my $eth = 0;
if (open FILE, $fname) {
    my $dataj = <FILE>;
    close FILE;
    my $data = &parse_json($dataj);
    $eth = $data->{"eth"};
    $start_block = $data->{"startBlock"};
}

my $addr = "0xa28FC2102Da86e424B37Ad86C7Bc7855fC441239";
my $url = "http://api.etherscan.io/api?module=account&action=txlist&address=$addr&startblock=$start_block&endblock=99999999&sort=asc&apikey=31DCRU6XIZCB6BUR65BCPYK77MEPJHM4HW";
my $raw = `curl -X GET "$url"`;

my $j = &parse_json($raw);
my $transactions = $j->{"result"};
my $msg = "";
foreach $tx (@$transactions) {
    if (!$tx->{'isError'}) {
        my $v = $tx->{'value'};
        $v /= 1000000000000000000;
        $msg .= "$v ETH ";
        $msg .= "from: $tx->{'from'}\n";
        $eth += $v
    }
    $start_block = $tx->{'blockNumber'};
}
print $msg;
print "TOTAL: $eth ETH\n";
open(my $fh, '>', $fname);
print $fh "{\"eth\":$eth,\"startBlock\":".($start_block+1)."}";
close $fh
