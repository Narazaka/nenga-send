use utf8;
use Encode;
use Encode::Guess qw/shift-jis euc-jp 7bit-jis utf16le utf16be/;
use File::Spec::Functions;
use File::Path;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat bundling);
use Nenga::Send;
binmode STDOUT, ':encoding(cp932)';
binmode STDERR, ':encoding(cp932)';

my $options = {};
Getopt::Long::GetOptions($options,
	qw(
		output|o=s
		preview|v=s
		from_postcode|p=s
		from_address|a=s
		from_name|n=s
		font|f=s
		resolution|r=i
		margin_left=f
		margin_top=f
		margin_right=f
		margin_bottom=f
	)
);
$options->{from_address} = Encode::decode('cp932', $options->{from_address});
$options->{from_name} = Encode::decode('cp932', $options->{from_name});
$options->{font} = Encode::decode('cp932', $options->{font});

my @to_list;
for my $list_file (@ARGV){
	open my $fh, '<', $list_file or die 'Cannot open file [',$list_file,']';
	flock $fh, 1;
	my $all = do{local $/;<$fh>};
	binmode $fh, ':encoding('.Encode::Guess->guess($all)->name.')';
	seek $fh, 0, 0;
	while (<$fh>){
		next if /^\s*#/;
		chomp;
		next if /^$/;
		my ($name, $honorific, $postcode, $address) = split /\t/;
		$name =~ s/\//\n/;
		$address =~ s/\s/\n/;
		$address =~ tr/０１２３４５６７８９－/0123456789-/;
		push @to_list, {name => $name, honorific => $honorific, postcode => $postcode, address => $address};
	}
	close $fh;
}

if(defined $options->{output} && ! -d $options->{output}){
	File::Path::make_path($options->{output}) or die 'Cannot create output path [',$options->{output},']';
}

my $ns = Nenga::Send->new(resolution => $options->{resolution} || 300,
	from_postcode => $options->{from_postcode} || '',
	from_address => $options->{from_address} || '',
	from_name => $options->{from_name} || '',
);
$ns->font($options->{font} ? Encode::encode('cp932', $options->{font}) : ());
$ns->preview($options->{preview});

for my $to (@to_list){
	print 'Processed ',$to->{name},"\n";
	$ns->build(
		to_postcode => $to->{postcode},
		to_address => $to->{address},
		to_name => $to->{name},
		honorific => $to->{honorific} || undef
	)->write(
		file_name => Encode::encode('cp932', catfile($options->{output}, $to->{name}.'.jpg')),
		margin => {
			left => $options->{margin_left},
			top => $options->{margin_top},
			right => $options->{margin_right},
			bottom => $options->{margin_bottom},
		}
	);
}
