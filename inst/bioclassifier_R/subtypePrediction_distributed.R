# this code & protocol has been validated externally by MDACC
#1. Download normalized expression data
#2. Log transform expression estimates
#3. Optionally median center or appropriately adjust each probeset, which carries the population assumption
#4. Map probesets to Entrez gene names
#5. Format as tab delimited text, with first row of sample names and first column of gene names
#---- This software then provides the following steps
#5. For probesets that map to identical Entrez gene names, select the one with highest IQR (for Affy, select mean for Agilent)
#6. Extract the 50 genes of interest (in pam50_centroids.txt)
#7. Calculate Spearman's rank correlation between each sample and each subtype centroid (in pam50_centroids.txt)
#8. Assign the class of the most highly correlated centroid to each sample

## Input variables for the subtype prediction script
#paramDir<- paste("./bioclassifier_R", sep = "") # the location of unchanging files such as the function library and main program
inputDir<- paste("./bioclassifier_data", sep = "") # the location of the data matrix, and where output will be located
inputFile<- "inputFile.txt" # the input data matrix as a tab delimited text file
short<-"outputFile" # short name that will be used for output files
calibrationParameters<- NA 	#the column of the "mediansPerDataset.txt" file to use for calibration; 
#NA will force centering within the test set & -1 will not do any 
#adjustment (when adjustment performed by used)
hasClinical<-FALSE 	#may include tumor size as second row, with 'T' as the gene name, 
#and encoded as binary (0 for size <= 2cm or 1 for size > 2cm)
#set this variable to FALSE if tumor size is not available
collapseMethod<-"mean" # can be mean or iqr (probe with max iqr is selected)
# typically, mean is preferred for long oligo and
# iqr is preferred for short oligo platforms

#calibrationFile<- paste(paramDir,"mediansPerDataset_v2.txt",sep="/")
calibrationFile<- system.file(package = 'miRLAB', 'bioclassifier_R', 'mediansPerDataset_v2.txt')
#trainCentroids<- paste(paramDir,"pam50_centroids.txt",sep="/")
trainCentroids<- system.file(package = 'miRLAB', 'bioclassifier_R', 'pam50_centroids.txt')
#trainFile<- paste(paramDir,"220arrays_nonUBCcommon+12normal_50g.txt",sep="/")
trainFile<- system.file(package = 'miRLAB', 'bioclassifier_R', '220arrays_nonUBCcommon+12normal_50g.txt')

proliferationGenes<-c("CCNB1","UBE2C","BIRC5","KNTC2","CDC20","PTTG1","RRM2","MKI67","TYMS","CEP55","CDCA1")
stdArray<-T # just for visualization, and only set to F if many missing genes
predFiles<- paste(inputDir,inputFile,sep="/")


###
# some constants
###

# for subtype only model
glthreshold<- -0.15
ghthreshold<-  0.1

# for subtype + proliferation model
gplthreshold<- -0.25
gphthreshold<-  0.1

# for combined model
clthreshold<- -0.1
chthreshold<-  0.2

# for combined + proliferation model
cplthreshold<- -0.2
cphthreshold<-  0.2

# begin analyses

# only need train data for visualizations
x<-readarray(trainFile,hr=2)
x$xd<-standardize(medianCtr(x$xd))

# load the published centroids for classifcation
pamout.centroids<-read.table(trainCentroids,sep="\t",header=T,row.names=1)

	pdfname1<-paste(inputDir,paste("predictionScores_pam50RankCorrelation_1_",short,".pdf",sep=""),sep="/")
	pdfname2<-paste(inputDir,paste("predictionScores_pam50RankCorrelation_2_",short,".pdf",sep=""),sep="/")
	clustername<-paste(inputDir,paste(short,"_PAM50_normalized_heatmap",sep=""),sep="/")
	outFile<- paste(inputDir,paste(short,"_pam50scores.txt",sep=""),sep="/")
	
	# read in the data file
	if(hasClinical){
		xhr=2
	}else{
		xhr=1
	}
	y<-readarray(predFiles,hr=xhr,method=collapseMethod,impute=F)
	
	# normalization
	if(is.na(calibrationParameters)){
		y$xd<-medianCtr(y$xd)
	}else{
		if(calibrationParameters != -1){
			medians<-readarray(calibrationFile,hr=1)
			print(paste("calibration to:",dimnames(medians$xd)[[2]][calibrationParameters]))
			tm<-overlapSets(medians$xd,y$xd)
			y$xd<-(tm$y-tm$x[,calibrationParameters])
			#y$xd<-(tm$y-tm$x[,calibrationParameters])/tm$x[,15]
		}
	}
	
	num.missing<- NA

	if(stdArray){
		y$xd<-standardize(y$xd)
	}

	erScore<-as.vector(t(y$xd["ESR1",]))
	her2Score<-as.vector(t(y$xd["ERBB2",]))
	
	# assign the subtype scores and calculate the proliferation score
	this.proliferationGenes<-dimnames(y$xd)[[1]] %in% proliferationGenes

	prolifScore<-apply(y$xd[this.proliferationGenes,],2,mean,na.rm=T)

	out<-sspPredict(pamout.centroids,classes="",y$xd,std=F,distm="spearman",centroids=T)
	out$distances<- -1*out$distances
	
	call.conf<-c()
	for(j in 1:length(out$predictions)){
		#####call.conf[j]<- 1-cor.test(out$testData[,j],out$centroids[,which(colnames(pamout.centroids)==out$predictions[j])],method="spearman")$p.value
		call.conf[j]<- 1-cor.test(out$testData[,j],out$centroids[,which(colnames(pamout.centroids)==out$predictions[j])],method="spearman", exact=FALSE)$p.value
	}
	call.conf<-round(call.conf,2)
	
	# calculate the risk scores
	genomic <- 0.04210193*out$distances[,1] + 0.12466938*out$distances[,2] + -0.35235561*out$distances[,3] + 0.14213283*out$distances[,4]
	genomicWprolif <- -0.0009299747*out$distances[,1] + 0.0692289192*out$distances[,2] + -0.0951505484*out$distances[,3] +  0.0493487685*out$distances[,4] + 0.3385116381*prolifScore
	if(hasClinical){
		xT<-as.numeric(as.vector(y$classes$T))
		combined <- 0.0442770*out$distances[,1] + 0.1170297*out$distances[,2] + -0.2608388*out$distances[,3] + 0.1055908*out$distances[,4] + 0.1813751*xT
		combinedWprolif <- -0.009383416*out$distances[,1] +  0.073725503*out$distances[,2] + -0.090436516*out$distances[,3] + 0.053013865*out$distances[,4] + 0.131605960*xT + 0.327259375*prolifScore
	}
	
	# threshold the risk score
	griskgroups<-genomic
	griskgroups[genomic>ghthreshold]<-"high"
	griskgroups[genomic>glthreshold & genomic<ghthreshold]<-"med"
	griskgroups[genomic<glthreshold]<-"low"
	gpriskgroups<-genomicWprolif
	gpriskgroups[genomicWprolif>gphthreshold]<-"high"
	gpriskgroups[genomicWprolif>gplthreshold & genomicWprolif<gphthreshold]<-"med"
	gpriskgroups[genomicWprolif<gplthreshold]<-"low"
	
	genomic<- 100* (genomic + 0.35 ) / 0.85
	genomicWprolif<- 100* (genomicWprolif + 0.35 ) / 0.85
	
	# write output files
	if(hasClinical){
		criskgroups<-combined
		criskgroups[combined>chthreshold]<-"high"
		criskgroups[combined>clthreshold & combined<chthreshold]<-"med"
		criskgroups[combined<clthreshold]<-"low"
		cpriskgroups<-combinedWprolif
		cpriskgroups[combinedWprolif>cphthreshold]<-"high"
		cpriskgroups[combinedWprolif>cplthreshold & combinedWprolif<cphthreshold]<-"med"
		cpriskgroups[combinedWprolif<cplthreshold]<-"low"
	
		combined<- 100* (combined + 0.35 ) / 0.85
		combinedWprolif<- 100* (combinedWprolif + 0.35 ) / 0.85
		
		outtable<-cbind(out$distances, out$predictions, call.conf, genomic, griskgroups, prolifScore, genomicWprolif, gpriskgroups, combined, criskgroups, combinedWprolif, cpriskgroups, erScore, her2Score)
		dimnames(outtable)[[2]]<-c("Basal","Her2","LumA","LumB","Normal","Call","Confidence",
																"ROR-S (Subtype Only)","ROR-S Group (Subtype Only)","Proliferation Score", 
																"ROR-P (Subtype + Proliferation)","ROR-P Group (Subtype + Proliferation)",
																"ROR-C (Subtype + Clinical)","ROR-C Group (Subtype + Clinical)",
																"ROR-PC (Subtype + Clinical + Proliferation)","ROR-PC Group (Subtype + Clinical + Proliferation)",
																"ER","Her2")
	}else{
		outtable<-cbind(out$distances, out$predictions, call.conf, genomic, griskgroups, prolifScore, genomicWprolif, gpriskgroups, erScore, her2Score)
		dimnames(outtable)[[2]]<-c("Basal","Her2","LumA","LumB","Normal","Call","Confidence",
																"ROR-S (Subtype Only)","ROR-S Group (Subtype Only)","Proliferation Score", 
																"ROR-P (Subtype + Proliferation)","ROR-P Group (Subtype + Proliferation)",
																"ER","Her2")
	}
	write.table(outtable,outFile,sep="\t",col.names=NA)
	
	# make some plots for evaluation
	print(paste("ER range:",quantile(erScore,.9,na.rm=T)-quantile(erScore,.1,na.rm=T)))
	
	subtypeColors<-out$predictions
	subtypeColors[subtypeColors=="Basal"]<-"red"
	subtypeColors[subtypeColors=="Her2"]<-"hotpink"
	subtypeColors[subtypeColors=="LumA"]<-"darkblue"
	subtypeColors[subtypeColors=="LumB"]<-"skyblue"
	subtypeColors[subtypeColors=="Normal"]<-"green"
	conf.colors<-call.conf
	conf.colors[call.conf>=0.95]<-"black"
	conf.colors[call.conf<0.95]<-"red"
	
	pdf(paste(clustername,".pdf",sep=""))
	#myHeatmap(out$testData,cbind(subtypeColors,conf.colors),file=paste(clustername,".cdt",sep=""),rowNames=rownames(out$testData))
	dev.off()
	
	pdf(pdfname1,height=10,width=12)
	pars<-par(no.readonly=T)
	myplot(out,short,prolifScore)
	dev.off()

	tm<-overlapSets(x$xd,y$xd)
	tm$x<-tm$x[,!is.na(x$classes$subtype)]
	tm<-cbind(tm$x,	impute.knn(as.matrix(tm$y))$data)
	classes<-matrix(nrow=4,ncol=dim(tm)[2])
	nTrainSamples<-length(x$classes$subtype[!is.na(x$classes$subtype)])

	classes[1,]<-c(rep("train",nTrainSamples),rep(short,dim(y$xd)[2]))
	classes[2,]<-c(x$classes$subtype[!is.na(x$classes$subtype)],rep(NA,dim(tm)[2]-dim(x$xd[,!is.na(x$classes$subtype)])[2]))
	classes[3,]<-c(rep(NA,dim(tm)[2]-length(out$predictions)),out$predictions)
	
	pdf(pdfname2,height=6,width=12)
	tm<-scale(tm,center=F)
	par(mfrow=c(1,3))
	pcaEA(tm,classes[1,],mainStr="Traing and Test sets",showNames=F,showClasses=F)
	pcaEA(tm[,!is.na(as.vector(t(classes[2,])))],classes[2,!is.na(as.vector(t(classes[2,])))],mainStr="Training cases",showNames=F,showClasses=F,groupColors=c("red","hotpink","darkblue","skyblue","green"))
	pcaEA(tm[,!is.na(as.vector(t(classes[3,])))],classes[3,!is.na(as.vector(t(classes[3,])))],mainStr="Test cases",showNames=F,showClasses=F,groupColors=c("red","hotpink","darkblue","skyblue","green"))
	par(pars)
	dev.off()
