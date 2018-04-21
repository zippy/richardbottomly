# a bot to send ETH sale notifications to mattermost via a webhook
# Copyleft 2018 (totally free)
use JSON::Parse 'parse_json';

while(true) {
    &check();
    sleep(60);
}

sub check {
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
	    $eth += $v;
	    $msg .= << "EOM";
| **Amount** | **$v ETH** |
|------------|------------|
| **From**   | **$tx->{'from'}** |
| Running Total | $eth ETH |
EOM

	}
	$start_block = $tx->{'blockNumber'};
    }
    open(my $fh, '>', $fname);
    print $fh "{\"eth\":$eth,\"startBlock\":".($start_block+1)."}";
    close $fh;

    if ($msg ne "") {
	my $post = <<"END_MSG";
Ooh. Someone seems to have sent ETH to your ICO! 

$msg
END_MSG
	&post($post);
    }
}

sub post {
    my $PLAYBOOKS_HOME = "/root/playbooks";
    my $BOT_VARS = "richard.bottomly";

    my $msg = shift;
    my $cmd = <<"END_CMD";
ansible-playbook -i ",localhost" -c local $PLAYBOOKS_HOME/mattermost-ansible/mattermost-post.yml --extra-vars="@/root/playbooks/mattermost-ansible/mattermost-post_$BOT_VARS.vars" --extra-vars="mattermost_post_text='$msg'"
END_CMD
   # print $cmd;
   # print "\n";
    # print `$cmd`;
    $cmd;
}
