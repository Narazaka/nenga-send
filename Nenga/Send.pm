package Nenga::Send;
use utf8;
use Encode qw/encode/;
use GD;
use Image::ExifTool;
use Mouse;
use Mouse::Util::TypeConstraints;

my $millimeter_per_inch = 25.4;
my $size_millimeter = {h => 100, v => 148};

subtype PositiveInt => (as 'Int', where { $_ > 0 }, message {"The number you provided, $_, was not a positive number"});
subtype PostCode => (as 'Str', where {/\d\d\d-?\d\d\d\d/ || $_ eq ''}, message {'"'.$_.'" is invalid. [NNN-NNNN]'});

has canvas => (is => 'ro', isa => 'GD::Image', writer => '_set_canvas');

has resolution => (is => 'rw', isa => 'PositiveInt', default => 360);

has preview => (is => 'rw', isa => 'Maybe[Str]');

has honorific => (is => 'rw', isa => 'Str', default => '様');

#has to_postcode => (is => 'rw', isa => 'PostCode');
#has to_address => (is => 'rw', isa => 'Str', required => 1);
#has to_name => (is => 'rw', isa => 'Str', required => 1);
has from_postcode => (is => 'rw', isa => 'PostCode');
has from_address => (is => 'rw', isa => 'Str');
has from_name => (is => 'rw', isa => 'Str');
has from_email => (is => 'rw', isa => 'Str');

has font => (is => 'rw', isa => 'Str', default => 'C:/Windows/Fonts/msgothic.ttc');
has str_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->font});
has number_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->font});
has to_str_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->str_font});
has to_number_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->number_font});
has from_str_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->str_font});
has from_number_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->number_font});
has to_postcode_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->to_number_font});
has to_address_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->to_str_font});
has to_name_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->to_str_font});
has from_postcode_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->from_number_font});
has from_address_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->from_str_font});
has from_name_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->from_str_font});
has from_email_font => (is => 'rw', isa => 'Str', lazy => 1, default => sub{shift->from_number_font});

has to_postcode_font_size => (is => 'rw', isa => 'PositiveInt', default => 4); # mm
has to_address_font_size => (is => 'rw', isa => 'PositiveInt', default => 6);
has to_name_font_size => (is => 'rw', isa => 'PositiveInt', default => 10);
has from_postcode_font_size => (is => 'rw', isa => 'PositiveInt', default => 3);
has from_address_font_size => (is => 'rw', isa => 'PositiveInt', default => 3);
has from_name_font_size => (is => 'rw', isa => 'PositiveInt', default => 5);
has from_email_font_size => (is => 'rw', isa => 'PositiveInt', default => 2);

sub BUILD{
	my $self = shift;
	return $self;
}

sub build{
	my $self = shift;
	my $options = {@_};
	$self->_set_canvas(GD::Image->new($self->_mm_to_pixel($size_millimeter->{h}), $self->_mm_to_pixel($size_millimeter->{v})));
	my $canvas = $self->canvas;
	my $white = $canvas->colorAllocate(255,255,255);
	my $black = $canvas->colorAllocate(0, 0, 0);
	$canvas->fill(0, 0, $white);
	if($options->{preview} || ($self->preview && ! defined $options->{preview})){
		my $preview_canvas = GD::Image->newFromPng($options->{preview} || $self->preview, 1);
		$canvas->copyResampled($preview_canvas, 0, 0, 0, 0, $canvas->getBounds(), $preview_canvas->getBounds());
	}
	{ # to_postcode
		my @to_postcode = grep {/\d/} split //, $options->{to_postcode};
		for my $cnt (0 .. $#to_postcode){
			$canvas->stringFT($black, $self->to_postcode_font, $self->_mm_to_pixel($self->to_postcode_font_size), 0, $self->_mm_to_pixel(45 + $cnt * 7), $self->_mm_to_pixel(17.5), $to_postcode[$cnt]);
		}
	}
	{ # to_address
		my @to_address = $self->_multiline_str_to_vertical($self->_num_to_kanji($options->{to_address}));
		my @buffers;
		my ($width, $height, $buf_canvas) = $self->_stringFT_buffered($to_address[0], $self->to_address_font, $self->_mm_to_pixel($self->to_address_font_size));
		push @buffers, {width => $width, height => $height, canvas => $buf_canvas};
		if($to_address[1]){
			my ($width, $height, $buf_canvas) = $self->_stringFT_buffered($to_address[1], $self->to_address_font, $self->_mm_to_pixel($self->to_address_font_size));
			push @buffers, {width => $width, height => $height, canvas => $buf_canvas};
		}
		if(! $to_address[1]){
			if($buffers[0]->{height} > $self->_mm_to_pixel(95)){
				$canvas->copyResampled($buffers[0]->{canvas}, $self->_mm_to_pixel(80), $self->_mm_to_pixel(24), 0, 0, $buffers[0]->{width}, $self->_mm_to_pixel(95), $buffers[0]->{width}, $buffers[0]->{height});
			}else{
				$canvas->copy($buffers[0]->{canvas}, $self->_mm_to_pixel(80), $self->_mm_to_pixel(24), 0, 0, $buffers[0]->{width}, $buffers[0]->{height});
			}
		}else{
			if($buffers[0]->{height} > $self->_mm_to_pixel(85) || $buffers[1]->{height} > $self->_mm_to_pixel(85)){
				my $long_height = $buffers[0]->{height} > $buffers[1]->{height} ? $buffers[0]->{height} : $buffers[1]->{height};
				my $ratio = $self->_mm_to_pixel(85) / $long_height;
				$canvas->copyResampled($buffers[0]->{canvas}, $self->_mm_to_pixel(83), $self->_mm_to_pixel(24), 0, 0, $buffers[0]->{width}, $buffers[0]->{height} * $ratio, $buffers[0]->{width}, $buffers[0]->{height});
				$canvas->copyResampled($buffers[1]->{canvas}, $self->_mm_to_pixel(73), $self->_mm_to_pixel(34 + 85) - $buffers[1]->{height} * $ratio, 0, 0, $buffers[1]->{width}, $buffers[1]->{height} * $ratio, $buffers[1]->{width}, $buffers[1]->{height});
			}else{
				$canvas->copy($buffers[0]->{canvas}, $self->_mm_to_pixel(83), $self->_mm_to_pixel(24), 0, 0, $buffers[0]->{width}, $buffers[0]->{height});
				$canvas->copy($buffers[1]->{canvas}, $self->_mm_to_pixel(73), $self->_mm_to_pixel(34 + 85) - $buffers[1]->{height}, 0, 0, $buffers[1]->{width}, $buffers[1]->{height});
			}
		}
	}
	{ # to_name
		my @to_name = map {$_."\n".$self->_str_to_vertical(defined $options->{honorific} ? $options->{honorific} : $self->honorific)} $self->_multiline_str_to_vertical($options->{to_name});
		if(!$to_name[1]){
			$canvas->stringFT($black, $self->to_name_font, $self->_mm_to_pixel($self->to_name_font_size), 0, $self->_mm_to_pixel(45), $self->_mm_to_pixel(42), $to_name[0]);
			# $canvas->stringFT($black, $self->to_name_font, $self->_mm_to_pixel($self->to_name_font_size), 0, $self->_mm_to_pixel(45), $self->_mm_to_pixel(36), $to_name[0]);
		}else{
			$canvas->stringFT($black, $self->to_name_font, $self->_mm_to_pixel($self->to_name_font_size), 0, $self->_mm_to_pixel(55), $self->_mm_to_pixel(42), $to_name[0]);
			$canvas->stringFT($black, $self->to_name_font, $self->_mm_to_pixel($self->to_name_font_size), 0, $self->_mm_to_pixel(37), $self->_mm_to_pixel(42), $to_name[1]);
		}
	}
	if($self->from_postcode){ # from_postcode
		my @from_postcode = grep {/\d/} split //, $self->from_postcode;
		for my $cnt (0 .. $#from_postcode){
			$canvas->stringFT($black, $self->from_postcode_font, $self->_mm_to_pixel($self->from_postcode_font_size), 0, $self->_mm_to_pixel(5.7 + $cnt * 4.2), $self->_mm_to_pixel(128), $from_postcode[$cnt]);
		}
	}
	if($self->from_address){ # from_address
		my @from_address = $self->_multiline_str_to_vertical($self->_num_to_kanji($self->from_address));
		$canvas->stringFT($black, $self->from_address_font, $self->_mm_to_pixel($self->from_address_font_size), 0, $self->_mm_to_pixel(29), $self->_mm_to_pixel(70), $from_address[0]);
		if($from_address[1]){
			$canvas->stringFT($black, $self->from_address_font, $self->_mm_to_pixel($self->from_address_font_size), 0, $self->_mm_to_pixel(24), $self->_mm_to_pixel(74), $from_address[1]);
		}
	}
	if($self->from_name){ # from_name
		my @from_name = $self->_multiline_str_to_vertical($self->from_name);
		if(!$from_name[1]){
			$canvas->stringFT($black, $self->from_name_font, $self->_mm_to_pixel($self->from_name_font_size), 0, $self->_mm_to_pixel(14), $self->_mm_to_pixel(80), $from_name[0]);
		}else{
			undef;
		}
	}
	return $self;
}

sub _mm_to_pixel{
	my $self = shift;
	my $size_mm = shift;
	return int $size_mm * $self->resolution / $millimeter_per_inch;
}

sub _num_to_kanji{
	my $self = shift;
	my $str = shift;
	$str =~ tr/０１２３４５６７８９/0123456789/;
	$str =~ tr/0123456789/〇一二三四五六七八九/;
	return $str;
}

sub _multiline_str_to_vertical{
	my $self = shift;
	my $str = shift;
	my @lines;
	for my $line (split /\n/, $str){
		push @lines, $self->_str_to_vertical($line);
	}
	return @lines;
}

sub _str_to_vertical{
	my $self = shift;
	my $str = shift;
	$str =~ s//\n/g;
	$str =~ s/^\n//;
	$str =~ s/\n$//;
	$str =~ s/[\-－ー]/｜/g;
	$str =~ tr/A-Za-z/Ａ-Ｚａ-ｚ/;
	return $str;
}

sub _stringFT_buffered{
	my $self = shift;
	my $str = shift;
	my $font = shift;
	my $font_size = shift;
	my $bounds;
	(undef, undef, $bounds->{right}, $bounds->{bottom}, undef, undef, $bounds->{left}, $bounds->{top}) = GD::Image->stringFT(0, $font, $font_size, 0, 0, 0, $str);
	my ($width, $height) = ($bounds->{right} - $bounds->{left}, $bounds->{bottom} - $bounds->{top});
	# warn "$bounds->{right}, $bounds->{bottom}, $bounds->{left}, $bounds->{top}";
	my $buf_canvas = GD::Image->new($width, $height);
	my $white = $buf_canvas->colorAllocate(255,255,255);
	my $black = $buf_canvas->colorAllocate(0,0,0);
	$buf_canvas->fill(0, 0, $white);
	$buf_canvas->stringFT($black, $font, $font_size, 0, - $bounds->{left}, - $bounds->{top}, $str);
	return $width, $height, $buf_canvas;
}

sub write{
	my $self = shift;
	my $options = {@_};
	my $canvas;
	if($options->{margin}){
		my %margin = map {$_ => $options->{margin}->{$_} || 0} qw(left top right bottom);
		$canvas = GD::Image->new($self->_mm_to_pixel($size_millimeter->{h} - $margin{left} - $margin{right}), $self->_mm_to_pixel($size_millimeter->{v} - $margin{top} - $margin{bottom}));
		$canvas->copy($self->canvas, 0, 0, $self->_mm_to_pixel($margin{left}), $self->_mm_to_pixel($margin{top}), $canvas->width, $canvas->height);
	}else{
		$canvas = $self->canvas;
	}
	open my $fh, '>:raw', $options->{file_name} or die 'Cannot write image file [', $options->{file_name}, ']';
	flock $fh, 2;
	print $fh $canvas->jpeg(100);
	close $fh;
	my $iet = Image::ExifTool->new();
	$iet->ExtractInfo($options->{file_name});
	$iet->SetNewValue(XResolution => $self->resolution);
	$iet->SetNewValue(YResolution => $self->resolution);
	# $iet->SetNewValue(resolutionunit => 'inchies');
	$iet->WriteInfo($options->{file_name});
	return $self;
}

1;
