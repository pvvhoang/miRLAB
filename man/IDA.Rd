% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/miRLAB.R
\name{IDA}
\alias{IDA}
\title{miRNA target prediction with the IDA method}
\usage{
IDA(
  datacsv,
  cause,
  effect,
  pcmethod = "original",
  alpha = 0.05,
  targetbinding = NA
)
}
\arguments{
\item{datacsv}{the input dataset in csv format}

\item{cause}{the column range that specifies the causes (miRNAs), e.g. 1:35}

\item{effect}{the column range that specifies the effects (mRNAs), e.g. 36:2000}

\item{pcmethod}{choose different versons of the PC algorithm, including "original" (default)
"stable", and "stable.fast"}

\item{alpha}{significance level for the conditional independence test, e.g. 0.05.}

\item{targetbinding}{the putative target, e.g. "TargetScan.csv". If targetbinding is not specified, only expression data is used.
If targetbinding is specified, the prediction results using expression data with be intersected with the interactions in the target binding file.}
}
\value{
A  matrix that includes the causal effects. Columns are miRNAs, rows are mRNAs.
}
\description{
Calculate the causal effect of each pair of miRNA-mRNA,and return a matrix of causal effects with columns are miRNAs and rows are mRNAs.
}
\examples{
dataset=system.file("extdata", "ToyEMT.csv", package="miRLAB")
results=IDA(dataset, 1:3, 4:18) 
}
\references{
1. Le, T.D., Liu, L., Tsykin, A., Goodall, G.J., Liu, B., Sun, B.Y. and Li, J. (2013) Inferring microRNA-mRNA causal regulatory relationships from expression data. Bioinformatics, 29, 765-71.

2. Zhang, J., Le, T.D., Liu, L., Liu, B., He, J., Goodall, G.J. and Li, J. (2014) Identifying direct miRNA-mRNA causal regulatory relationships in heterogeneous data. J. Biomed. Inform., 52, 438-47.

3. Maathuis, H.M., Colombo, D., Kalisch, M. and Buhlmann, P. (2010) Predicting causal effects in large-scale systems from observational data. Nat. Methods, 7, 247-249.

4. Maathuis, H.M., Kalisch, M. and Buhlmann, P. (2009) Estimating high-dimensional intervention effects from observational data. Ann. Stat., 37, 3133-3164.
}
