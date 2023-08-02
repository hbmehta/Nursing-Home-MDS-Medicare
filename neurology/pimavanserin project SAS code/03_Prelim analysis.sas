/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:39:50 PM
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

/*   START OF NODE: 03_Prelim analysis   */
%LET _CLIENTTASKLABEL='03_Prelim analysis';
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
	Identify prkisnon pts -- Medpar	
**************************************************************************/
%macro medpar (yr = );
	Data park_m_&yr;
	set &lib.MEDPAR&yr._R9984 (keep = bene_id dgns_1_cd--dgns_25_cd admsn_dt dschrg_dt los_day_cnt);
	parkinson = 0;
	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
	end;
	if parkinson = 1;
	run;

	proc sort data=park_m_&yr;
	by bene_id admsn_dt;
	run;
%mend medpar;
%medpar (yr = 16);
%medpar (yr = 17);
%medpar (yr = 18);


/**************************************************************************
	Identify G20 pts -- OUTSAF	
**************************************************************************/
%macro outsaf (yr = );
	Data park_o_&yr;
	set &lib.OTPTCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25 clm_thru_dt);
		parkinson = 0;
		array diag icd_dgns_cd1--icd_dgns_cd25;
		do i = 1 to dim(diag);
		if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
		end;
		if parkinson = 1;
	run;

	proc sort data=park_o_&yr;
	by bene_id clm_thru_dt;
	run;
%mend outsaf;
%outsaf (yr = 16);
%outsaf (yr = 17);
%outsaf (yr = 18);


/**************************************************************************
	Identify G20 pts -- CARRIER	
**************************************************************************/
%macro carrier (yr = );
	Data park_c_&yr;
	set &lib.BCARCLMSK&yr._R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12 clm_thru_dt);
		parkinson = 0;
		array diag icd_dgns_cd1-icd_dgns_cd12;
		do i = 1 to dim(diag);
		if substr (diag(i),1,3) in ("G20") or diag (i) in ("G3183") then parkinson = 1; 
		end;
		if parkinson = 1;
	run;

	proc sort data=park_c_&yr;
	by bene_id clm_thru_dt;
	run;
%mend carrier;
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
%partd (yr = 16);
%partd (yr = 17);
%partd (yr = 18);

/**************************************************************************
	Stack all claims	- M, O and C
**************************************************************************/
data park_m (keep=bene_id admsn_dt rename= (admsn_dt = park_date)); 	
set park_m_16 park_m_17 park_m_18; 
run;

data park_o (keep=bene_id clm_thru_dt rename= (clm_thru_dt = park_date)); 
set park_o_16 park_o_17 park_o_18; 
run;

data park_c (keep=bene_id clm_thru_dt rename= (clm_thru_dt = park_date)); 
set park_c_16 park_c_17 park_c_18; 
run;

data park_d (keep=bene_id srvc_dt rename= (srvc_dt = park_date)); 	
set park_d_16 park_d_17 park_d_18; 
run;

Data park_mocd;
	set park_m (in=m) park_o (in=o) park_c (in=c) park_d (in=d);
		if m then data_source= 'm';
		if o then data_source= 'o';
		if c then data_source= 'c';
		if d then data_source= 'd';
run;

proc sort data = park_mocd; by bene_id park_date; run;

data pima.park_mocd;
set park_mocd;
run;

Data park_mocd_u;		
	set park_mocd;
	by bene_id;
	if first.bene_id;
run;

proc freq data=park_mocd_u;
tables data_source;
run;

data pima.park_mocd_u;    **Study cohort -- unique pts -- 601,265 patients;
set park_mocd_u;
run;

/**************************************************************************
	ALL pimavanserin claims
	Pimavanserin has only 3 ndc codes
			"63090010030", "63090017060", "63090034030"
**************************************************************************/

%macro pima_drug (yr = );
	Data pima&yr;
		set &lib.PDE&yr._R9984 (keep=  bene_id srvc_dt gnn days_suply_num prod_srvc_id) ;
		where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
	run;
%mend pima_drug;

%pima_drug (yr = 16);
%pima_drug (yr = 17);
%pima_drug (yr = 18);

Data pima.pima_clm (rename = (srvc_dt = pima_dt));   **All pimavanserin claims;
	set pima16 pima17 pima18;
run;

**102871 pimavanserin claims and 9759 unique patients;
proc sql;
select count (bene_id) as all_clms, count (distinct bene_id) as unique_pts
from pima.pima_clm;
quit;

/**************************************************************************
	Create cohort	
**************************************************************************/
proc sql;
create table  cohort_v01 as
select * 
from pima.park_mocd_u as a left join pima.pima_clm as b
on a.bene_id = b.bene_id
order by bene_id, park_date, pima_dt;
quit;

Data cohort_v02;
set cohort_v01;
by bene_id;
if first.bene_id;
if pima_dt = . then pimavanserin = 0; else pimavanserin = 1;
if  pima_dt NE . and  pima_dt < park_date then drug_b4_diag = 1; 
diff_day = pima_dt - park_date;
run;

proc freq data =  cohort_v02;			**226 patients out of 9421 pimavanserin useras have Rx date before Dx date;
tables pimavanserin*drug_b4_diag / missing;
run;
proc means data =  cohort_v02 maxdec= 0;	
var diff_day;
where drug_b4_diag = 1; 
run;

proc sql;
select count (bene_id) as all_clams, count (distinct bene_id) as unique_pt
from cohort_v02;
quit;




















/**************************************************************************
		Preevious useless codes	
**************************************************************************/

Data pima_all_clm;
set pima16_pt  pima17_pt  pima18_pt;
run;
proc sql;
create table pima_all_pt as 
select bene_id, max (pima_drug) as pima_drug_v1
from pima_all_clm
group by bene_id;
quit;

proc freq data =  pima16_pt;  tables pima_drug / missing; run;
proc freq data =  pima17_pt;  tables pima_drug / missing; run;
proc freq data =  pima18_pt;  tables pima_drug / missing; run;
proc freq data =  pima_all_pt; tables pima_drug_v1 / missing; run;

/**************************************************************************
	Merge diagnosis and prescription data - yearly and overall
**************************************************************************/
proc sql;
create table cohort_16 as select * from
g20_moc_16_pt as a left join pima16_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_16; set cohort_16; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_17 as select * from
g20_moc_17_pt as a left join pima17_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_17; set cohort_17; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_18 as select * from
g20_moc_18_pt as a left join pima18_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_18; set cohort_18; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_all as select * from
g20_moc_all_pt as a left join pima_all_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_all; set cohort_all; if pima_drug_v1 = . then pima_drug_v1 = 0; run;

/**************************************************************************
	Analysis
**************************************************************************/
proc freq data =  cohort_16;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_17;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_18;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_all; tables parkinson_diag_v2*pima_drug_v1 / missing; run;



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
