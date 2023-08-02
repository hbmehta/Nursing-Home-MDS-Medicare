/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:36 PM
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

/*   START OF NODE: Pima_PD_cross tab   */
%LET _CLIENTTASKLABEL='Pima_PD_cross tab';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;


options compress = no;
libname pima "&mylibs/pima";
%let lib = in055546.;


/**************************************************************************
	Identify parkisnon pts -- Medpar	
**************************************************************************/
%macro medpar (yr = );
	Data park_m_&yr;
	set &lib.MEDPAR&yr._R9984 (keep = bene_id dgns_1_cd--dgns_25_cd admsn_dt dschrg_dt los_day_cnt);
	parkinson = 0;
	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
	end;
	run;

	proc sort data=park_m_&yr;
	by bene_id admsn_dt;
	run;
%mend medpar;
%medpar (yr = 15);
%medpar (yr = 16);
%medpar (yr = 17);
%medpar (yr = 18);


/**************************************************************************
	Identify parkisnon pts -- OUTSAF	
**************************************************************************/
%macro outsaf (yr = );
	Data park_o_&yr;
	set &lib.OTPTCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25 clm_thru_dt);
		parkinson = 0;
		array diag icd_dgns_cd1--icd_dgns_cd25;
		do i = 1 to dim(diag);
		if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
		end;
	run;

	proc sort data=park_o_&yr;
	by bene_id clm_thru_dt;
	run;
%mend outsaf;
%outsaf (yr = 15);
%outsaf (yr = 16);
%outsaf (yr = 17);
%outsaf (yr = 18);


/**************************************************************************
	Identify parkisnon pts -- CARRIER	
**************************************************************************/
%macro carrier (yr = );
	Data park_c_&yr;
	set &lib.BCARCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12 clm_thru_dt);
		parkinson = 0;
		array diag icd_dgns_cd1-icd_dgns_cd12;
		do i = 1 to dim(diag);
		if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
		end;
	run;

	proc sort data=park_c_&yr;
	by bene_id clm_thru_dt;
	run;
%mend carrier;
%carrier (yr = 15);
%carrier (yr = 16);
%carrier (yr = 17);
%carrier (yr = 18);

/**************************************************************************
		Identify levodopa/carbidopa -- part D	
**************************************************************************/
data ndc_levo_carbi;
set _uplds.redbook2018 (keep=gennme ndcnum);
where gennme in ("Levodopa", "Carbidopa/Levodopa", "Carbidopa/Entacapone/Levodopa");
run;

%macro partd (yr = );
	proc sql;
		create table park_d_&yr as
		select a.bene_id, a.srvc_dt, a.gnn, a.days_suply_num, a.prod_srvc_id
		from &lib.pde&yr._R9984 as a, ndc_levo_carbi as b
		where a.prod_srvc_id = b.ndcnum
		order by a.bene_id, a.srvc_dt;
	quit;
%mend partd;
%partd (yr = 15);
%partd (yr = 16);
%partd (yr = 17);
%partd (yr = 18);

/**************************************************************************
	Stack all claims	- M, O, C and D
**************************************************************************/
data park_m (keep=bene_id admsn_dt parkinson rename= (admsn_dt = park_date)); 	
set park_m_16 park_m_17 park_m_18; 
run;

data park_o (keep=bene_id clm_thru_dt parkinson rename= (clm_thru_dt = park_date)); 
set park_o_16 park_o_17 park_o_18; 
run;

data park_c (keep=bene_id clm_thru_dt parkinson rename= (clm_thru_dt = park_date)); 
set park_c_16 park_c_17 park_c_18; 
run;

data park_d (keep=bene_id srvc_dt parkinson rename= (srvc_dt = park_date)); 	
set park_d_16 park_d_17 park_d_18;
parkinson=1; 
run;

Data park_mocd;
	set park_m (in=m) park_o (in=o) park_c (in=c) park_d (in=d);
		if m then data_source= 'm';
		if o then data_source= 'o';
		if c then data_source= 'c';
		if d then data_source= 'd';
run;
proc sql;
	create table park_mocd_2 as
	select bene_id, max(parkinson) as parkinson
	from park_mocd
	group by bene_id;
quit;
proc sort data = park_mocd_2 nodup; by bene_id parkinson; run;

/**************************************************************************
	Part D drug data	
**************************************************************************/
Data pima.pima16;
set &lib.PDE16_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima17;
set &lib.PDE17_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima18;
set &lib.PDE18_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

proc sql; 
create table pima16_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima16;
quit;
proc sql; 
create table pima17_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima17;
quit;
proc sql; 
create table pima18_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima18;
quit;

Data pima_all_clm;
set pima16_pt  pima17_pt  pima18_pt;
run;
proc sql;
create table pima_all_pt as 
select bene_id, max (pima_drug) as pima_drug_v1
from pima_all_clm
group by bene_id;
quit;

/**************************************************************************
	Merge diagnosis and prescription data - yearly and overall
**************************************************************************/
proc sql;
create table cohort_all as select * from
park_mocd_2 as a left join pima_all_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_all; set cohort_all; if pima_drug_v1 = . then pima_drug_v1 = 0; run;


proc freq data =  cohort_all; tables parkinson*pima_drug_v1 / missing; run;

/* From how many facilities */
data pima;
	set cohort_all;
	if pima_drug_v1=1;
	keep bene_id;
run;

libname anticoag "&mylibs/anticoag";
libname opioid "&mylibs/opioid";
%let lib = in055546.;

data mds; set 
&lib.mds_asmt315_R9984 (keep=bene_id a1600_entry_dt trgt_dt state_cd fac_prvdr_intrnl_id)
&lib.mds_asmt316_R9984 (keep=bene_id a1600_entry_dt trgt_dt state_cd fac_prvdr_intrnl_id)
&lib.MDS_ASMT317_R9984 (keep=bene_id a1600_entry_dt trgt_dt state_cd fac_prvdr_intrnl_id)
&lib.MDS_ASMT318_R9984 (keep=bene_id a1600_entry_dt trgt_dt state_cd fac_prvdr_intrnl_id);
fac_id = cats(state_cd, fac_prvdr_intrnl_id);
run;

proc sql;
	create table cohort_2 as
	select bene_id, fac_id, trgt_dt
	from mds
	where bene_id in (select distinct bene_id from pima);
quit;
proc sort data=cohort_2 nodup; by bene_id; run;

data cohort_2;
	set cohort_2;
	format trgt_dt mmddyy10.;
	adm_month = month(trgt_dt);
	adm_year = year(trgt_dt);
run;


proc sql; 
create table pima16 as 
select distinct bene_id, 1 as pima_drug, min(srvc_dt) as pima_dt
from pima.pima16;
quit;
proc sql; 
create table pima17 as 
select distinct bene_id, 1 as pima_drug , min(srvc_dt) as pima_dt
from pima.pima17;
quit;
proc sql; 
create table pima18 as 
select distinct bene_id, 1 as pima_drug , min(srvc_dt) as pima_dt
from pima.pima18;
quit;

Data pima_all;
set pima16  pima17  pima18;
run;
proc sql;
create table pima_all_2 as 
select bene_id, max (pima_drug) as pima_drug_v1, min(pima_dt) as pima_dt
from pima_all
group by bene_id;
quit;
data pima_all_2;
	set pima_all_2;
	format pima_dt mmddyy10.;
	pima_month = month(pima_dt);
	pima_year = year(pima_dt);
run;

proc sql;
	create table cohort_3 as
	select *
	from pima_all_2 a
	inner join cohort_2 b
	on a.bene_id=b.bene_id and a.pima_year=b.adm_year and a.pima_month=b.adm_month;
quit;
proc sql;
	create table cohort_3 as
	select *
	from pima_all_2 a
	inner join cohort_2 b
	on a.bene_id=b.bene_id and a.pima_year=b.adm_year;
quit;
data cohort_4;
	set cohort_3;
	keep bene_id fac_id;
run;
proc sort data=cohort_4 nodup; by bene_id; run;
data cohort_5;
	set cohort_4;
	by bene_id;
	if first.bene_id then count=1;
	else count+1;
	if count=1;
run;
proc sql;
	select count(distinct fac_id) as fac_count format = comma16.
	from cohort_5;
quit;

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
