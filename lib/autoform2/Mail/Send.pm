package autoform2::Mail::Send;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( send_app_confirm send_link );

sub send_app_confirm
# //////////////////////////////////////////////////
{
	my ( $self, $appnumber, $appid ) = @_; 
	
	$appnumber = $self->{ vars }->get_system->appnum_to_str( $appnumber );
	
	my $replacer = {
		app_num		=> $appnumber,
		app_id		=> $appid,
		app_token	=> $self->{ token },
	};
	
	my ( $app_list, undef ) = $self->get_list_of_app();
	
	for ( @$app_list ) {
		$replacer->{ app_list } .= $_->{ FName } . ' ' . $_->{ LName } . '<br>';
	}
	$replacer->{ app_list } =~ s/\<br\>$//;
	
	my $lang_local = VCS::Site::autodata::get_appointment_text();
	
	$lang_local->{ $_ } = $self->lang( $lang_local->{ $_ } ) for keys %$lang_local;

	my $subject = $lang_local->{ subject } . ", #$appnumber";
	
	my $conf = $self->{ autoform }->{ confirm };
	
	my $html = $self->get_file_content( $conf->{ tt } );

	my $data = $self->db->query( "
		SELECT EMail, CenterID, TimeslotID, AppDate, dwhom, FName, LName, MName, Category
		FROM Appointments
		JOIN VisaTypes ON Appointments.VType = VisaTypes.ID
		WHERE Appointments.ID = ?
		ORDER BY Appointments.ID DESC LIMIT 1", $appid
	)->[ 0 ];
	
	$replacer->{ branch_addr } = $self->lang( 'Address-' . $data->{ CenterID } );
	
	$replacer->{ branch_addr } = $self->db->query( "
		SELECT BAddr FROM Branches WHERE ID = ?", $data->{ CenterID }
		
	) if $replacer->{ branch_addr } eq 'Address-' . $data->{ CenterID };

	
	$replacer->{ branch_addr } = $self->{ vars }->get_system->converttext( $replacer->{ branch_addr } );
	
	$replacer->{ branch_addr } =~ s/_?(x005F|x000D)_?//g;
	
	my ( $tstart, $tend ) = $self->db->query( "
		SELECT TStart, TEnd FROM TimeData WHERE SlotID = ?", $data->{ TimeslotID }
	);
		
	my @date_sp = split( /\-/, $data->{ AppDate } );

	my $months = VCS::Site::autodata::get_months();

	$replacer->{ date_time } = 
		$date_sp[ 2 ] . ' ' . $self->lang( $months->{ $date_sp[ 1 ] } ) . ' ' . $date_sp[ 0 ] . ', ' . 
		$self->{ vars }->get_system->time_to_str( $tstart );
	
	$replacer->{ app_person } = ( !$data->{ dwhom } ? '<b>' . $lang_local->{ pers } .'</b>' : 
		$lang_local->{ by_the_doc } . ' <b>' . 
		$data->{ LName } . ' ' . $data->{ FName } . ' ' .  $data->{ MName } . '</b>' 
	);
	
	my $spb_center = ( VCS::Site::autodata::this_is_spb_center( $data->{ CenterID } ) ? "spb_" : "" );
	
	$replacer->{ link_image } = $conf->{ link_image };
	$replacer->{ link_site } = $conf->{ link_site };
	$replacer->{ app_email } = $conf->{ $spb_center . "html_email" };
	$replacer->{ app_website } = $conf->{ html_website };
	
	my $elements = VCS::Site::autodata::get_html_elements();
	my $edit_app_button = ( $data->{ Category } eq "C" ? $elements->{ edit_app_button } : "" );
	
	$html =~ s/\[%edit_app_button%\]/$edit_app_button/;

	for ( keys %$replacer ) {
		$html =~ s/\[%$_%\]/$replacer->{ $_ }/g;
	}
	
	for ( keys %$lang_local ) {
		$html =~ s/\[%$_%\]/$lang_local->{ $_ }/g;
	};
	
	$self->{ vars }->{'session'}->{'login'} = 'website';
	
	my $agreem = $self->get_file_content( $conf->{ pers_data } );
	
	my $atach = {
		0 => {
			'filename'	=> "Appointment.pdf", 
			'data'		=> VCS::Docs::appointments->new( 'VCS::Docs::appointments', $self->{ vars } )->createPDF( $appid ), 
			'ContentType'	=> 'application/pdf',
		},
		1 => {
			'filename'	=> "Согласие.pdf", 
			'data'		=> $agreem, 
			'ContentType'	=> 'application/pdf',
		}
	};
	
	$self->{ vars }->get_system->send_mail( $self->{ vars }, $data->{ EMail }, $subject, $html, 1, $atach );
}

sub send_link
# //////////////////////////////////////////////////
{
	my ( $self, $email ) = @_;
	
	my $subject = $self->lang( 'Вы начали запись на подачу документов на визу' );
	
	my $htmls = VCS::Site::autodata::get_link_text();
	
	my $body;
	
	my $token_with_lang = $self->{ token } . '&lang=' . ( $self->{ 'lang' } || 'ru' );
	
	for my $html ( sort { $a <=> $b } keys %$htmls ) {
		
		$htmls->{ $html } =~ s/\[token\]/$token_with_lang/;
		
		$body .= $self->lang( $htmls->{ $html } );
	}
	
	$self->{ vars }->get_system->send_mail( $self->{ vars }, $email, $subject, $body, 1 );

	return $self->db->query( "
		UPDATE AutoToken SET LinkSended = now() WHERE Token = ?", {}, $self->{ token }
	);
}

1;