% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/miRLAB.R
\name{Kendall}
\alias{Kendall}
\title{miRNA target prediction with the Kendall correlation coefficient method}
\usage{
Kendall(datacsv, cause, effect, targetbinding = NA)
}
\arguments{
\item{datacsv}{the input dataset in csv format}

\item{cause}{the column range that specifies the causes (miRNAs), e.g. 1:35}

\item{effect}{the column range that specifies the effects (mRNAs), e.g. 36:2000}

\item{targetbinding}{the putative target, e.g. "TargetScan.csv". If targetbinding is not specified, only expression data is used.
If targetbinding is specified, the prediction results using expression data with be intersected with the interactions in the target binding file.}
}
\value{
A  matrix that includes the Kendall correlation coefficients. Columns are miRNAs, rows are mRNAs.
}
\description{
Calculate the Kendall correlation coefficient of each pair of miRNA-mRNA,and return a matrix of correlation coefficients with columns are miRNAs and rows are mRNAs.
}
\examples{
dataset=system.file("extdata", "ToyEMT.csv", package="miRLAB")
results=Kendall(dataset, 1:3, 4:18) 
}
\references{
Kendall, M. (1938) A new measure of rank correlation. Biometrika, 30, 81 - 9.
}
