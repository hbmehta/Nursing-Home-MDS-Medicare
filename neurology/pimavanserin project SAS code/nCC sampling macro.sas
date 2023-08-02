/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:41:07 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: nCC sampling macro   */
%LET _CLIENTTASKLABEL='nCC sampling macro';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;


************************************************************************************************;
*   Program:		nCC sampling macro for incidence density sampling.sas						;
*																								;
*   Citation:		Desai RJ et al. American journal of epidemiology. 2016:183(10):949-957		;							
************************************************************************************************;

%macro nCCsampling (total_samples=1, in_data= , n_controls= , outcome_var= , ptime_var= , 
id_var= , additional_matching_var=0, match1_var=dummy1, match2_var=dummy2, match3_var= dummy3, 
score_match='no', score_var=dummy4, caliper= , sorting_var=number, variable_ratio_match='no', lib=work, 
out_data= , save_n_info=n_info, save_estimates=estimates);

%put dummy1-dummy4 above are variables generated within the macro for when you do not provide matching variables;

*for large files, the log window may become full. So insetad of clearing it every now and then, 
lets create a separate log file. The default is null, you should specify a pathname if
you want it in a specific location;


%do sample_no= 1 %to &total_samples;

** before we beging sampling, lets create several variables that will help us in the process **;

*to properly execute the match, we need some dummy matching variables for when the user doesnt want to 
match on any factors. So we create them here, we will drop them later;

data test; set &in_data; dummy1=0; dummy2=0; dummy3=0; dummy4=0; run;

*** Now, we are ready to begin sampling;

	%let sampling=‘yes’;
	** Enumerate Cases **;
	data cases;
	set test;
	if &outcome_var=1;
	run;

	data cases;
	set cases end=eof;
	if eof then call symput ('ncases', put(_n_,6.));	**  CALL SYMPUT takes value from a DATA step and 
        assigns it to a macro variable which you can then use later in your program. **;
	run;
	** Create Risk Set **;

	%do iter = 1 %to &ncases;

	data temp_case;
	set cases;
	if _n_ =&iter ;
	call symput ("rs", put(_n_,6.)); *risk set number;
	call symput ("time_rs", put(&ptime_var,8.7)); *time when the risk set is sampled=date of case becoming a case;
	call symput ("case_id", put(&id_var,12.)); *case identification number, which is used to prevent accidental sampling
												of a case as its own control;

	*now if you provided additinal matching variables, lets create provisions for them. This program lets you match
	on 3 additional variables,  you can add similar statements for using more than 3 variables;

    call symput ("var1_rs", put (&match1_var, 12.)); 
    call symput ("var2_rs", put (&match2_var, 12.)); 
    call symput ("var3_rs", put (&match3_var, 12.)); 
    call symput ("score_rs", put (&score_var, 8.7)); 
	run;
	
	*now lets separate out the potential controls. For that we need to test a variety of conditions based 
	on the matching factors. First approach is when we are not doing any score based matching but 
	more traditional variable matching;

	%if &score_match='no' %then %do;

	proc sql;
	create table temp_control as
	select * 
	from test;
	quit;

	**Relax matching criteria here**;

	data temp_control; set temp_control; 

	if (0 <= &time_rs <=&ptime_var) then condition0=1; *controls are only eligible for sampling if they are event free on the date of case becoming a case; 

	if (0 <= &time_rs <=&ptime_var) and (&var1_rs=&match1_var) then condition1=1;

    if (0 <= &time_rs <=&ptime_var) and (&var1_rs=&match1_var) 
    and (&var2_rs=&match2_var) then condition2=1; 

	if (0 <= &time_rs <=&ptime_var) and (&var1_rs=&match1_var) 
    and (&var2_rs=&match2_var) and (&var3_rs=&match3_var) then condition3=1;

	run;
 	*only keep controls that meet all the matching conditions and hence eligible for selection;

	data temp1_control;
	set temp_control; 
	if condition&additional_matching_var=1;
	run; %end; *end traditional match loop;

	*next is when we are interested in score based matching such as disease risk score match or propensity score
	match;

	%if &score_match='yes' %then %do;

	data temp_control;
	set test;
 	if (0 <= &time_rs <=&ptime_var) and ((&score_var-(&caliper))<&score_rs<(&score_var+(&caliper))); *Matched on the score variable with caliper provided by the user;
 
	run; 

	data temp1_control; set temp_control;
	abs_diff=abs(&score_rs-&score_var);*create an absolute difference variable that is equal to DRS of the case (drs_rs) and the drs of 
						 potential control. This will later be used to perfom match;
	run; 
	%end; *end score match loop;

	** Exclude Index Case **;
	data temp1_control; 
	set temp1_control;
	if &id_var=&case_id then delete;
	number=ranuni(0);
	time_rs=&time_rs;
	var1_rs=&var1_rs;
	var2_rs=&var2_rs;
	var3_rs=&var3_rs;
	score_rs=&score_rs;
	&outcome_var=0;
	run;

	**Sample Controls **;
	%if &sampling=‘yes’ %then %do;
	proc sort data=temp1_control;
	by &sorting_var; *default is sorting by randomly generated variable number, overridden by the absolute difference variable in case of score-based matching;

	data temp_control1;
	set temp1_control;
	by time_rs;
	retain m;
	if first.time_rs then m=0;
	m=m+1;
	if m<=&n_controls then output temp_control1; *only select a pre-specified number of controls as requested by the user;
	run;
	%end; * End If Sampling=yes;

	** Combine Case with Controls **;
	data rs&iter;
	set temp_case
	temp_control1;
	rs=&rs;
	time_rs=&time_rs;
	var1_rs=&var1_rs;
	var2_rs=&var2_rs;
	var3_rs=&var3_rs;
	score_rs=&score_rs;
	drop dummy1-dummy4 condition0-condition3; *drop the dummy matching variables in absence of real matching variables;
	run;

	%end; * End Loop Creating Risk Set;

	** Append Risk Sets **;

	%do j = 2 %to &ncases;
	proc append base = rs1 data = rs&j;
	run;
	%end;
	data final; set rs1; run;

*save the total number of events observed in this dataset;

proc sql noprint;
select count (distinct rs)
into: total_events
from final;
quit;

	** delete individual risk sets generated within this macro to reduce clutter in the work library;
	%do k=1 %to &total_events;
	proc delete data = rs&k;
	run;
	quit;
	%end;

*datasets f1 and f2 are to determine the number of patients in each risk set;

data f1;set final; keep rs m n1;
by rs m; 
if first.rs then n1=0;
n1+rs;
if last.rs then output;
run;

data f2; set f1; n_in_rs=n1/rs;
drop n1;
run; *number of observations=number of risk sets;

*For fixed ratio matching: only keep the risk sets that have pre specified controls per case;

%if &variable_ratio_match='no' %then %do;

proc sql;
create table f3 as
select *
from f2 (drop = m)
where n_in_rs=&n_controls+1;
quit;

%end; *end fixed ratio matching loop;

%if &variable_ratio_match='yes' %then %do;

proc sql;
create table f3 as
select *
from f2 (drop = m)
where n_in_rs>1;
quit;

%end; *end variable ratio matching loop: In this process, ALL the cases will be included as long as at least
1 control is found for them;

*Merge with the earlier created final dataset;

data final1; merge final f3(in=s);
by rs;
if s; 
run;

proc sort data=final1; by rs m; run;

*create a status variable represeing cases (1) and controls (2);

data &lib..&out_data&sample_no;
set final1;
status=1;
if m ne . then status=2;
label status='1=cases and 2=controls';
label var1_rs='First matching variable for the risk set';
label var2_rs='Second matching variable for the risk set';
label var3_rs='Third matching variable for the risk set';
label time_rs='Time when cases and controls sampled';
label rs='Risk set';
label n_in_rs='Total number of patients in each risk set';
label score_rs='Score matching variable for the risk set';
label number='Randomly generated number';
label abs_diff='Difference in score between control and the case';
drop m n1;
run;

*save the total number of events observed in this dataset;

proc sql noprint;
select count (distinct rs)
into :events_analysed
from &lib..&out_data&sample_no;
quit;

*identify how many cases were successfully matched and how many were not;

data n_&sample_no;
sample=&sample_no;
total_cases=&total_events;
cases_matched=&events_analysed;
run;



*stamp the sample number variable on each output datasets;

data pm_&sample_no; set pm_&sample_no;
sample=&sample_no;
run;

%end; 

*lets append the two created datasets for situations where sampling is done more than once;

	%do n = 1 %to &total_samples;

	proc append base=n data=n_&n;
	run;
	proc append base=est data = pm_&n; 
	run;

	%end;


*save the outputs before deleting them; 

data &lib..&save_n_info; set n; run;
data &lib..&save_estimates; set est; run;

*The following statements delete the base version and rename the youngest historical version to the base version. This is done because otherwise proc append keeps 
adding output rows to your output dataset across different runs, which is often times not desirable;

proc datasets NOLIST;
   delete n (gennum=0);
quit;

proc datasets NOLIST;
 delete est (gennum=0);
quit;

	** delete redundant datasets to reduce clutter in the work library;

proc datasets NOLIST; delete test temp_control temp1_control temp_Control1
temp_case final n_1-n_&total_samples pm_1-pm_&total_samples f1 f2 f3 final1; run;


%mend;

options nosource;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
