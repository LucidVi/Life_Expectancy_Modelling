*Setting options and path macros;
options validvarname=v7;
*%let data_path = C:/Users/vaibh/Documents/Capstone_5110/Raw_Data;
%let libname_path = C:/Users/vaibh/Documents/Capstone_5110;
*resolving slash discrepancy;
%macro setdelim;
   %global delim;
   %if %index(&path,%str(/)) %then %let delim=%str(/);
   %else %let delim=%str(\);
%mend;
*Setting libname;
libname project base "&libname_path/Library_Path";

*libname meandata base "&libname_path/Raw_Data/mean_data";
*Macro based loop to load all the data files;
%macro px;
%let value = life_expectancy tuberculosis dpt gdp_per_capita 
				health_expenditure_percent pollution
				alcohol_per_capita access_to_electricity
				sanitation_basic waged_salaried_employees
				non_communicable_diseases anemia measles_immunization
				mortality_road_traffic primary_gross_enrollment;


%local i next_value;
%let i=1;
%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
*Proc import step to load a single file;

	proc import datafile="&libname_path/Raw_Data/&next_value"

	out=project.&next_value

        dbms=xls
        replace;
		
		sheet="Data";
		namerow=4;
		startrow=5;
         
getnames=no;
run;

*Proc import ends;
%let i = %eval(&i + 1);

%end;

%mend;
%px;
*Loop ends;
*Macro based loop to apply proc contents on each file;
%macro px;
%let value = life_expectancy tuberculosis dpt gdp_per_capita 
				health_expenditure_percent pollution
				alcohol_per_capita access_to_electricity
				sanitation_basic waged_salaried_employees
				non_communicable_diseases anemia measles_immunization
				mortality_road_traffic;


%local i next_value;
%let i=1;
%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
*Proc content step to analyze a single file;
title &next_value;
	proc means data=project.&next_value;
	run;
	title;
*Proc content ends;
%let i = %eval(&i + 1);

%end;

%mend;
%px;
*Loop ends;
proc import datafile="&libname_path/Raw_Data/country_code"

	out=project.country_code

        dbms=xls
        replace;
		
		sheet="Sheet1";
	
         
getnames=yes;
run;
*Combining data - only relevant variable;
proc sql;

     create table combineddata as

     select life_expectancy.Country_Name,
	 life_expectancy.Country_Code,
	 life_expectancy._2016 as life_expectancy,

     country_code.Region,country_code.Income_group,
	 country_code.Country,

     tuberculosis._2016 as tuberculosis_per_100k, 
	 dpt._2016 as dpt_vaccine,
	 pollution._2016 as pollutionpm,
	 health_expenditure_percent._2016 as health_expenditure_percent,
	 alcohol_per_capita._2016 as alcohol_per_capita,
	 gdp_per_capita._2016 as gdp_per_capita,
	 access_to_electricity._2016 as access_to_electricity,
	sanitation_basic._2016 as sanitation_basic,
    waged_salaried_employees._2016 as waged_salaried_employees,
    non_communicable_diseases._2016 as non_communicable_diseases, 
    anemia._2016 as anemia, 
	measles_immunization._2016 as measles_immunization,
	mortality_road_traffic._2016 as mortality_road_traffic,
	primary_gross_enrollment._2016 as primary_gross_enrollment
	 

     FROM 
	 project.life_expectancy
	
	 left join project.country_code 
	 on life_expectancy.Country_Code = country_code.Code
	 full join project.tuberculosis 
	 on life_expectancy.Country_Code = tuberculosis.Country_Code
	 full join project.dpt
	 on life_expectancy.Country_Code = dpt.Country_Code
	 full join project.pollution 
	 on life_expectancy.Country_Code = pollution.Country_Code
     full join project.health_expenditure_percent
	 on life_expectancy.Country_Code = health_expenditure_percent.Country_Code
     full join project.alcohol_per_capita 
	 on life_expectancy.Country_Code = alcohol_per_capita.Country_Code
     full join project.gdp_per_capita
     on life_expectancy.Country_Code = gdp_per_capita.Country_Code
	 full join project.access_to_electricity
     on life_expectancy.Country_Code = access_to_electricity.Country_Code
	 full join project.sanitation_basic
     on life_expectancy.Country_Code = sanitation_basic.Country_Code
	 full join project.waged_salaried_employees
     on life_expectancy.Country_Code = waged_salaried_employees.Country_Code
	 full join project.non_communicable_diseases
     on life_expectancy.Country_Code = non_communicable_diseases.Country_Code
	 full join project.anemia
     on life_expectancy.Country_Code = anemia.Country_Code
	 full join project.measles_immunization
     on life_expectancy.Country_Code = measles_immunization.Country_Code
	 full join project.mortality_road_traffic
     on life_expectancy.Country_Code = mortality_road_traffic.Country_Code
     full join project.primary_gross_enrollment
     on life_expectancy.Country_Code = primary_gross_enrollment.Country_Code
        
; 
where Country_Name ne .;
quit;
proc freq data=combineddata nlevels;
run;
data countrydata;
set work.combineddata;
where Country="Yes";
run;
*Macro do loop for summary tables;
%macro px;
%let value = life_expectancy tuberculosis_per_100k dpt_vaccine gdp_per_capita 
				health_expenditure_percent pollutionpm
				alcohol_per_capita access_to_electricity
				sanitation_basic waged_salaried_employees
				non_communicable_diseases anemia measles_immunization
				mortality_road_traffic primary_gross_enrollment;

%local i next_value;
%let i=1;
%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
*Proc import step to load a single file;

	proc summary data=countrydata;
class Region;
var &next_value;
output out=&next_value mean=meanvalue;
run;

*Proc import ends;
%let i = %eval(&i + 1);

%end;

%mend;
%px;
*Merging average;
proc sql;
create table clean_interim as
select countrydata.*,
life_expectancy.meanvalue as life_expectancy_mean,
tuberculosis_per_100k.meanvalue as tuberculosis_per_100k_mean,
dpt_vaccine.meanvalue as dpt_vaccine_mean,
gdp_per_capita.meanvalue as gdp_per_capita_mean,
health_expenditure_percent.meanvalue as health_expenditure_percent_mean,
pollutionpm.meanvalue as pollutionpm_mean,
alcohol_per_capita.meanvalue as alcohol_per_capita_mean,
access_to_electricity.meanvalue as access_to_electricity_mean,
sanitation_basic.meanvalue as sanitation_basic_mean,
waged_salaried_employees.meanvalue as waged_salaried_employees_mean,
non_communicable_diseases.meanvalue as non_communicable_diseases_mean,
anemia.meanvalue as anemia_mean,
measles_immunization.meanvalue as measles_immunization_mean,
mortality_road_traffic.meanvalue as mortality_road_traffic_mean,
primary_gross_enrollment.meanvalue as primary_gross_enrollment_mean

from countrydata
left join life_expectancy
on countrydata.Region=life_expectancy.Region
left join tuberculosis_per_100k
on countrydata.Region=tuberculosis_per_100k.Region
left join dpt_vaccine
on countrydata.Region=dpt_vaccine.Region
left join gdp_per_capita
on countrydata.Region=gdp_per_capita.Region
left join health_expenditure_percent
on countrydata.Region=health_expenditure_percent.Region
left join pollutionpm
on countrydata.Region=pollutionpm.Region
left join alcohol_per_capita
on countrydata.Region=alcohol_per_capita.Region
left join access_to_electricity
on countrydata.Region=access_to_electricity.Region
left join sanitation_basic
on countrydata.Region=sanitation_basic.Region
left join waged_salaried_employees
on countrydata.Region=waged_salaried_employees.Region
left join non_communicable_diseases
on countrydata.Region=non_communicable_diseases.Region
left join anemia
on countrydata.Region=anemia.Region
left join measles_immunization
on countrydata.Region=measles_immunization.Region
left join mortality_road_traffic
on countrydata.Region=mortality_road_traffic.Region
left join primary_gross_enrollment
on countrydata.Region=primary_gross_enrollment.Region
;
quit;
*Clean Columns;
data clean_final;
set clean_interim;
if life_expectancy=.
then life_expectancy_clean = life_expectancy_mean;
else life_expectancy_clean = life_expectancy;
if tuberculosis_per_100k=.
then tuberculosis_per_100k_clean = tuberculosis_per_100k_mean;
else tuberculosis_per_100k_clean = tuberculosis_per_100k;
if dpt_vaccine=.
then dpt_vaccine_clean = dpt_vaccine_mean;
else dpt_vaccine_clean = dpt_vaccine;
if gdp_per_capita=.
then gdp_per_capita_clean = gdp_per_capita_mean;
else gdp_per_capita_clean = gdp_per_capita;
if health_expenditure_percent=.
then health_expenditure_percent_clean = health_expenditure_percent_mean;
else health_expenditure_percent_clean = health_expenditure_percent; 
if pollutionpm=.
then pollutionpm_clean = pollutionpm_mean;
else pollutionpm_clean = pollutionpm;
if alcohol_per_capita=.
then alcohol_per_capita_clean = alcohol_per_capita_mean;
else alcohol_per_capita_clean = alcohol_per_capita;
if access_to_electricity=.
then access_to_electricity_clean = access_to_electricity_mean;
else access_to_electricity_clean = access_to_electricity;
if sanitation_basic=.
then sanitation_basic_clean = sanitation_basic_mean;
else sanitation_basic_clean = sanitation_basic;
if waged_salaried_employees=.
then waged_salaried_employees_clean = waged_salaried_employees_mean;
else waged_salaried_employees_clean = waged_salaried_employees;
if non_communicable_diseases=.
then non_communicable_diseases_clean = non_communicable_diseases_mean;
else non_communicable_diseases_clean = non_communicable_diseases;
if anemia=.
then anemia_clean = anemia_mean;
else anemia_clean = anemia;
if measles_immunization=.
then measles_immunization_clean = measles_immunization_mean;
else measles_immunization_clean = measles_immunization;
if mortality_road_traffic=.
then mortality_road_traffic_clean = mortality_road_traffic_mean;
else mortality_road_traffic_clean = mortality_road_traffic;
if primary_gross_enrollment=.
then primary_gross_enrollment_clean = primary_gross_enrollment_mean;
else primary_gross_enrollment_clean = primary_gross_enrollment;
run;
*Preparing final data set for modelling;
data project.life_expectancy_and_indicators;
set clean_final;
keep Country_Name Country_Code Region
Income_group life_expectancy_clean
tuberculosis_per_100k_clean dpt_vaccine_clean
gdp_per_capita_clean health_expenditure_percent_clean
pollutionpm_clean alcohol_per_capita_clean access_to_electricity_clean
sanitation_basic_clean waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean mortality_road_traffic_clean
primary_gross_enrollment_clean;
run;


*Correlation matrix;
proc corr data=project.life_expectancy_and_indicators
;var life_expectancy_clean tuberculosis_per_100k_clean
 dpt_vaccine_clean alcohol_per_capita_clean
 gdp_per_capita_clean health_expenditure_percent_clean
pollutionpm_clean; run;
ods graphics on;
*linear regression explanatory model proc reg backward;
proc reg data = project.life_expectancy_and_indicators plots=all;
   model life_expectancy_clean
= tuberculosis_per_100k_clean
dpt_vaccine_clean
pollutionpm_clean
health_expenditure_percent_clean
alcohol_per_capita_clean
gdp_per_capita_clean
access_to_electricity_clean
sanitation_basic_clean
waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean mortality_road_traffic_clean
primary_gross_enrollment_clean/selection=backward vif slstay=0.05 cp;
run;
ods graphics off;

*outlier checking process;
ods graphics on;

%let outlier_inputs=tuberculosis_per_100k_clean
dpt_vaccine_clean gdp_per_capita_clean
access_to_electricity_clean
non_communicable_diseases_clean anemia_clean 
;    /* independent variables */
%let outlier_response=life_expectancy_clean;                   /* dependent variable */
%let outlier_idvar=Country_Name;                                    /* ID variable */

%macro outliers(dsn=);
    title1 'Generate Outlier Statistics ';
    proc reg data=&dsn;
        model &outlier_response=&outlier_inputs / r influence;
        output rstudent=rstudent dffits=dffits cookd=cooksd out=temp;
    run;
    quit;
    data _null_;
        call symputx('numparms',length("%cmpres(&outlier_inputs)")-
                length(compress("%cmpres(&inputs)")) + 2);
    run;
    data influential;
        set temp nobs=numobs;
        retain cutdffits cutcooksd;
        if _n_=1 then do;
            cutdffits=2*(sqrt(&numparms/numobs));
            cutcooksd=4/numobs;
        end;
        rstudent_i=(abs(rstudent) > 3);
        dffits_i=(abs(dffits) > cutdffits);
        cooksd_i=(cooksd > cutcooksd);
        if rstudent_i + dffits_i + cooksd_i > 0;
    run;
    title1 'Observations Exceeding Suggested Cutoffs';
    proc print data=influential;
        var &outlier_idvar rstudent cooksd dffits cutcooksd cutdffits
            rstudent_i cooksd_i dffits_i;
    run;
%mend outliers;

%outliers(dsn=project.life_expectancy_and_indicators)
ods graphics off;
*removing outlier;
data life_expectancy_minus_outliers;
set project.life_expectancy_and_indicators;
where Country_Name ne "Monaco";
drop mortality_road_traffic_clean;
run;
*running proc glmselect for backward selection reg model;
ods graphics on;
proc glmselect data=life_expectancy_minus_outliers plots=all;
	backward: model life_expectancy_clean
= tuberculosis_per_100k_clean
dpt_vaccine_clean
pollutionpm_clean
health_expenditure_percent_clean
alcohol_per_capita_clean
gdp_per_capita_clean
access_to_electricity_clean
sanitation_basic_clean
waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean
primary_gross_enrollment_clean / selection=backward slstay=0.05;
	title "Backward Model Selection for SalePrice - SL 0.05";
run;
ods graphics off;

*Preparing test data lines 403-611;
proc sql;

     create table testdata_initial as

     select life_expectancy.Country_Name,
	 life_expectancy.Country_Code,
	 life_expectancy._2010 as life_expectancy,

     country_code.Region,country_code.Income_group,
	 country_code.Country,

     tuberculosis._2010 as tuberculosis_per_100k, 
	 dpt._2010 as dpt_vaccine,
	 pollution._2010 as pollutionpm,
	 health_expenditure_percent._2010 as health_expenditure_percent,
	 alcohol_per_capita._2010 as alcohol_per_capita,
	 gdp_per_capita._2010 as gdp_per_capita,
	 access_to_electricity._2010 as access_to_electricity,
	sanitation_basic._2010 as sanitation_basic,
    waged_salaried_employees._2010 as waged_salaried_employees,
    non_communicable_diseases._2010 as non_communicable_diseases, 
    anemia._2010 as anemia, 
	measles_immunization._2010 as measles_immunization,
	mortality_road_traffic._2010 as mortality_road_traffic,
	primary_gross_enrollment._2010 as primary_gross_enrollment
	 

     FROM 
	 project.life_expectancy
	
	 left join project.country_code 
	 on life_expectancy.Country_Code = country_code.Code
	 full join project.tuberculosis 
	 on life_expectancy.Country_Code = tuberculosis.Country_Code
	 full join project.dpt
	 on life_expectancy.Country_Code = dpt.Country_Code
	 full join project.pollution 
	 on life_expectancy.Country_Code = pollution.Country_Code
     full join project.health_expenditure_percent
	 on life_expectancy.Country_Code = health_expenditure_percent.Country_Code
     full join project.alcohol_per_capita 
	 on life_expectancy.Country_Code = alcohol_per_capita.Country_Code
     full join project.gdp_per_capita
     on life_expectancy.Country_Code = gdp_per_capita.Country_Code
	 full join project.access_to_electricity
     on life_expectancy.Country_Code = access_to_electricity.Country_Code
	 full join project.sanitation_basic
     on life_expectancy.Country_Code = sanitation_basic.Country_Code
	 full join project.waged_salaried_employees
     on life_expectancy.Country_Code = waged_salaried_employees.Country_Code
	 full join project.non_communicable_diseases
     on life_expectancy.Country_Code = non_communicable_diseases.Country_Code
	 full join project.anemia
     on life_expectancy.Country_Code = anemia.Country_Code
	 full join project.measles_immunization
     on life_expectancy.Country_Code = measles_immunization.Country_Code
	 full join project.mortality_road_traffic
     on life_expectancy.Country_Code = mortality_road_traffic.Country_Code
     full join project.primary_gross_enrollment
     on life_expectancy.Country_Code = primary_gross_enrollment.Country_Code
        
; 
where Country_Name ne .;
quit;


data testcountrydata;
set work.testdata_initial;
where Country="Yes";
run;
*Macro do loop for summary tables;
%macro px;
%let value = life_expectancy tuberculosis_per_100k dpt_vaccine gdp_per_capita 
				health_expenditure_percent pollutionpm
				alcohol_per_capita access_to_electricity
				sanitation_basic waged_salaried_employees
				non_communicable_diseases anemia measles_immunization
				 primary_gross_enrollment;

%local i next_value;
%let i=1;
%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
*Proc import step to load a single file;

	proc summary data=testcountrydata;
class Region;
var &next_value;
output out=test_&next_value mean=meanvalue;
run;

*Proc import ends;
%let i = %eval(&i + 1);

%end;

%mend;
%px;
*Merging average;
proc sql;
create table testdata_interim as
select testcountrydata.*,
test_life_expectancy.meanvalue as life_expectancy_mean,
test_tuberculosis_per_100k.meanvalue as tuberculosis_per_100k_mean,
test_dpt_vaccine.meanvalue as dpt_vaccine_mean,
test_gdp_per_capita.meanvalue as gdp_per_capita_mean,
test_health_expenditure_percent.meanvalue as health_expenditure_percent_mean,
test_pollutionpm.meanvalue as pollutionpm_mean,
test_alcohol_per_capita.meanvalue as alcohol_per_capita_mean,
test_access_to_electricity.meanvalue as access_to_electricity_mean,
test_sanitation_basic.meanvalue as sanitation_basic_mean,
test_waged_salaried_employees.meanvalue as waged_salaried_employees_mean,
test_non_communicable_diseases.meanvalue as non_communicable_diseases_mean,
test_anemia.meanvalue as anemia_mean,
test_measles_immunization.meanvalue as measles_immunization_mean,
test_primary_gross_enrollment.meanvalue as primary_gross_enrollment_mean

from testcountrydata
left join test_life_expectancy
on testcountrydata.Region=test_life_expectancy.Region
left join test_tuberculosis_per_100k
on testcountrydata.Region=test_tuberculosis_per_100k.Region
left join test_dpt_vaccine
on testcountrydata.Region=test_dpt_vaccine.Region
left join test_gdp_per_capita
on testcountrydata.Region=test_gdp_per_capita.Region
left join test_health_expenditure_percent
on testcountrydata.Region=test_health_expenditure_percent.Region
left join test_pollutionpm
on testcountrydata.Region=test_pollutionpm.Region
left join test_alcohol_per_capita
on testcountrydata.Region=test_alcohol_per_capita.Region
left join test_access_to_electricity
on testcountrydata.Region=test_access_to_electricity.Region
left join test_sanitation_basic
on testcountrydata.Region=test_sanitation_basic.Region
left join test_waged_salaried_employees
on testcountrydata.Region=test_waged_salaried_employees.Region
left join test_non_communicable_diseases
on testcountrydata.Region=test_non_communicable_diseases.Region
left join test_anemia
on testcountrydata.Region=test_anemia.Region
left join test_measles_immunization
on testcountrydata.Region=test_measles_immunization.Region
left join test_primary_gross_enrollment
on testcountrydata.Region=test_primary_gross_enrollment.Region
;
quit;
*Clean Columns;
data testdata_final;
set testdata_interim;
if life_expectancy=.
then life_expectancy_clean = life_expectancy_mean;
else life_expectancy_clean = life_expectancy;
if tuberculosis_per_100k=.
then tuberculosis_per_100k_clean = tuberculosis_per_100k_mean;
else tuberculosis_per_100k_clean = tuberculosis_per_100k;
if dpt_vaccine=.
then dpt_vaccine_clean = dpt_vaccine_mean;
else dpt_vaccine_clean = dpt_vaccine;
if gdp_per_capita=.
then gdp_per_capita_clean = gdp_per_capita_mean;
else gdp_per_capita_clean = gdp_per_capita;
if health_expenditure_percent=.
then health_expenditure_percent_clean = health_expenditure_percent_mean;
else health_expenditure_percent_clean = health_expenditure_percent; 
if pollutionpm=.
then pollutionpm_clean = pollutionpm_mean;
else pollutionpm_clean = pollutionpm;
if alcohol_per_capita=.
then alcohol_per_capita_clean = alcohol_per_capita_mean;
else alcohol_per_capita_clean = alcohol_per_capita;
if access_to_electricity=.
then access_to_electricity_clean = access_to_electricity_mean;
else access_to_electricity_clean = access_to_electricity;
if sanitation_basic=.
then sanitation_basic_clean = sanitation_basic_mean;
else sanitation_basic_clean = sanitation_basic;
if waged_salaried_employees=.
then waged_salaried_employees_clean = waged_salaried_employees_mean;
else waged_salaried_employees_clean = waged_salaried_employees;
if non_communicable_diseases=.
then non_communicable_diseases_clean = non_communicable_diseases_mean;
else non_communicable_diseases_clean = non_communicable_diseases;
if anemia=.
then anemia_clean = anemia_mean;
else anemia_clean = anemia;
if measles_immunization=.
then measles_immunization_clean = measles_immunization_mean;
else measles_immunization_clean = measles_immunization;
if primary_gross_enrollment=.
then primary_gross_enrollment_clean = primary_gross_enrollment_mean;
else primary_gross_enrollment_clean = primary_gross_enrollment;
drop mortality_road_traffic;
run;

data life_expectancy_test;
set testdata_final;
keep Country_Name Country_Code Region
Income_group life_expectancy_clean
tuberculosis_per_100k_clean dpt_vaccine_clean
gdp_per_capita_clean health_expenditure_percent_clean
pollutionpm_clean alcohol_per_capita_clean access_to_electricity_clean
sanitation_basic_clean waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean 
primary_gross_enrollment_clean;
run;


*Training and Validation Final step model;
ods graphics on;
proc glmselect data=life_expectancy_minus_outliers plots=all valdata=life_expectancy_test;
    model life_expectancy_clean=tuberculosis_per_100k_clean dpt_vaccine_clean
gdp_per_capita_clean health_expenditure_percent_clean
pollutionpm_clean alcohol_per_capita_clean access_to_electricity_clean
sanitation_basic_clean waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean 
primary_gross_enrollment_clean/ selection=backward choose=validate; 
    store out=finaloutput; 
    title "Selecting the Best Model using Honest Assessment";
run;
ods graphics off;


*DO NOT RUN CODE BEYOND THIS;




*linear regression explanatory model;
proc reg data = project.life_expectancy_and_indicators plots=all;
   model life_expectancy_clean
= tuberculosis_per_100k_clean
dpt_vaccine_clean
pollutionpm_clean
health_expenditure_percent_clean
alcohol_per_capita_clean
gdp_per_capita_clean
access_to_electricity_clean
sanitation_basic_clean
waged_salaried_employees_clean
non_communicable_diseases_clean anemia_clean
measles_immunization_clean mortality_road_traffic_clean
primary_gross_enrollment_clean/selection=adjrsq rsquare cp;
run;
ods graphics off;
*Anova Models;
  proc ANOVA data=clean_final
	
	class Region
	model life_expectancy_mean = Region
	means Region / Tukey alpha=0.05
	run;

*Anova for Region;
	ods graphics;
ods select lsmeans diff diffplot controlplot;
  proc glm data=clean_final;
	
	class Region;
	model life_expectancy_clean = Region;
	lsmeans Region / adjust=tukey alpha=0.05;
	run;
	ods graphics off;
	quit;

*Anova for Income group;
ods graphics;
ods select lsmeans diff diffplot controlplot;
  proc glm data=clean_final;
	
	class Income_group;
	model life_expectancy_clean = Income_group;
	lsmeans Income_group / adjust=tukey alpha=0.05;
	run;
	ods graphics off;
	quit;
ods graphics;
ods select lsmeans diff diffplot controlplot;
title1 "Anova Region";
proc glm data=clean_final plots(only)=(diffplot(center) controlplot);

	class Region;
	model life_expectancy_clean = Region;
	lsmeans Region / pdiff=ALL
						adjust= tukey; 
	lsmeans Region / pdiff=control('0')
						adjust= dunnett; 
	lsmeans Region / pdiff=ALL
						adjust= t;
run;
ods graphics off;
quit;
*DO NOT RUN THIS PART BELOW THIS LINE;
proc import datafile="&data_path/country_code"

	out=project.country_code

        dbms=xls
        replace;
		
		sheet="Sheet1";
         
getnames=yes;
run;
proc sql;

     create table combineddatafinal as
select combineddata.*,country_code.Country,
country_code.Region, country_code.Income_group
from combineddata

full join project.country_code 
	 on combineddata.Country_Code = country_code.Code;
quit;	 
proc summary data=combineddatafinal(where=(Country="Yes"));
class Region;
var tuberculosis_per_100k pollution;
output out=clsummry  mean=tuberculosis_per_100_mean ;
run;
proc sql;

     create table combineddatafinal2 as
select combineddatafinal.*,clsummry.tuberculosis_per_100_mean

from combineddatafinal

inner join clsummry
	 on combineddatafinal.Region = clsummry.Region;
quit;
*Getting correlation values;
proc corr data=combineddata
; run;
*modelling;
proc reg data = combineddata;
   model life_expectancy
= tuberculosis_per_100k 
dpt_vaccine
pollutionpm
health_expenditure_percent
alcohol_per_capita
gdp_per_capita;
run;
*Combining data - only relevant variable;
proc sql;

     create table combineddatatest as

     select life_expectancy.Country_Name,
	life_expectancy.Country_Code,
	 life_expectancy._2010 as life_expectancy,
%macro px;
%let value =  tuberculosis dpt gdp_per_capita 
				health_expenditure_percent pollution
				alcohol_per_capita;
&next_value._2010
FROM 
	project.life_expectancy
	 full join project.&next_value 
	 on life_expectancy.Country_Code = &next_value.Country_Code

%local i next_value;
%let i=1;
%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
*Proc import step to load a single file;

*Proc import ends;
%let i = %eval(&i + 1);

%end;

%mend;
%px;
quit;

tuberculosis._2010 as tuberculosis_per_100k, 
	dpt._2010 as dpt_vaccine,
	pollution._2010 as pollutionpm,
	health_expenditure_percent._2010 as health_expenditure_percent,
	alcohol_per_capita._2010 as alcohol_per_capita,
	gdp_per_capita._2010 as gdp_per_capita
	
	 

     FROM 
	project.life_expectancy
	 full join project.tuberculosis 
	 on life_expectancy.Country_Code = tuberculosis.Country_Code
	 full join project.dpt
	 on life_expectancy.Country_Code = dpt.Country_Code
	 full join project.pollution 
	 on life_expectancy.Country_Code = pollution.Country_Code
full join project.health_expenditure_percent
	 on life_expectancy.Country_Code = health_expenditure_percent.Country_Code
     full join project.alcohol_per_capita 
	 on life_expectancy.Country_Code = alcohol_per_capita.Country_Code
     full join project.gdp_per_capita
     on life_expectancy.Country_Code = gdp_per_capita.Country_Code; 

quit;
*Getting correlation values;
proc corr data=clean_final
;var life_expectancy_clean tuberculosis_per_100k_clean
 dpt_vaccine_clean alcohol_per_capita_clean
 gdp_per_capita_clean health_expenditure_percent_clean
pollutionpm_clean; run;
*modelling;
proc reg data = combineddata;
   model life_expectancy
= tuberculosis_per_100k 
dpt_vaccine
pollutionpm
health_expenditure_percent
alcohol_per_capita
gdp_per_capita;
run;
proc sql
SELECT id, scenario, expiresAt 
FROM generalTable
    JOIN facebookTable
        ON generalTable.id = facebookTable.id
    JOIN chiefTable
        ON generalTable.id = chiefTable.id

%macro px;
%let value = life_expectancy tuberculosis;
array areverse {4} cesd4 cesd8 cesd12 cesd18

%local i next_value;
%let i=1;

%do %while (%scan(&value, &i) ne );
   %let next_value = %scan(&value, &i);
	data &next_value_final;
set project.&next_value(keep = Country_Name Country_Code _2018 _2008 );
rename _2018=&next_value_2018
       _2008=&next_value_2008;
	   run;

%let i = %eval(&i + 1);

%end;

%mend;
%px;
%ARRAY(filename values = life_expectancy tuberculosis)
%do_over filename;
data filename[i]_final;
set project.filename[i](keep = Country_Name Country_Code _2018 _2008 );
rename _2018=filename[i]_2018
       _2008=filename[i]_2008;
	   run;
	   %end;
data cesd;
 set in.cesd1;
 
 do over areverse;
 areverse=3-areverse;
 end;
data life_expectancy_final;
set project.life_expectancy(keep = Country_Name Country_Code _2018 _2008 );
rename _2018=life_expectancy_2018
       _2008=life_expectancy_2008;
	   run;
proc import datafile="&data_path/life_expectancy.xls"

out=project.life_expectancy

        dbms=xls
        replace;
		
		sheet="Data";
		namerow=4;
		startrow=5;
         
getnames=no;
run;
data project.life_expectancy;
set project.life_expectancy;
rename _1960-_2019=life_expectancy_1960-life_expectancy_2019;
run;
proc import datafile="&data_path/tuberculosis.xls"
out=project.tuberculosis
        dbms=xls
        replace;
		sheet="Data";
		namerow=4;
		startrow=5;
     
getnames=no;
run;
data project.tuberculosis;
set project.tuberculosis;
rename _1960-_2019=tuberculosis_1960-tuberculosis_2019;
run;
