package autoform2::Data::AutodataTypeC;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( dummy_data );

sub dummy_data
# //////////////////////////////////////////////////
{
	my $token = shift;
	
	my $standart_date_check = 'zD^(([012]\d|3[01])\.((0\d)|(1[012]))\.(19\d\d|20[0-3]\d))$';
	my $standart_date_check_opt = 'D^(([012]\d|3[01])\.((0\d)|(1[012]))\.(19\d\d|20[0-3]\d))$';
	
	return [
		{
			type => 'input',
			name => 's_date',
			label => 'Дата начала поездки',
			comment => 'Введите предполагаемую дату начала поездки',
			example => '31.12.1900',
			check => $standart_date_check,
			check_logic => [
				{
					condition => 'now_or_later',
					offset => '[collect_date_offset]',
				},
				{
					condition => 'now_or_earlier',
					offset => 270,
					equality_is_also_fail => 1,
					full_error => 'Действует ограничение на максимальную дату вылета: не более [offset] с текущей даты',
				},
			],
			db => {
				table => 'Appointments',
				name => 'SDate',
			},
			special => 'datepicker, mask',
			minimal_date => 'current',
		},
		{
			type => 'input',
			name => 'f_date',
			label => 'Дата окончания запрашиваемой визы',
			comment => 'Введите предполагаемую дату окончания запрашиваемой визы',
			example => '31.12.1900',
			check => $standart_date_check,
			check_logic => [
				{
					condition => 'equal_or_later',
					table => 'Appointments',
					name => 'SDate',
					error => 'Дата начала поездки',
				},
			],
			db => {
				table => 'Appointments',
				name => 'FDate',
			},
			special => 'datepicker, mask',
			minimal_date => 's_date',
		},
		{
			type => 'input',
			name => 'rulname',
			label => 'Фамилия',
			comment => 'Введите фамилию на русском языке так, как она указана во внутреннем паспорте',
			example => 'Петров',
			check => 'zWЁ\s\-',
			check_logic => [
				{
					condition => 'english_only_for_not_rf_citizen',
					full_error => 'Для граждан РФ фамилию необходимо вводить на русском языке',
				},
			],
			db => {
				table => 'AppData',
				name => 'RLName',
			},
			format => 'capitalized'
		},
		{
			type => 'input',
			name => 'rufname',
			label => 'Имя',
			comment => 'Введите имя на русском языке так, как оно указано во внутреннем паспорте',
			example => 'Петр',
			check => 'zWЁ\s\-',
			check_logic => [
				{
					condition => 'english_only_for_not_rf_citizen',
					full_error => 'Для граждан РФ имя необходимо вводить на русском языке',
				},
			],
			db => {
				table => 'AppData',
				name => 'RFName',
			},
			format => 'capitalized'
		},
	];
};

1;