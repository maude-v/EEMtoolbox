% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summarise_ecosystem_features_Baker.R
\name{summarise_ecosystem_features_Baker}
\alias{summarise_ecosystem_features_Baker}
\title{Summary of ecosystem features for the Bimler-Baker model}
\usage{
summarise_ecosystem_features_Baker(parameters, sim_args)
}
\arguments{
\item{parameters}{a vector of sampled parameters}

\item{sim_args}{a list of arguments as returned by \link[EEMtoolbox]{args_function}}
}
\value{
vector of values: first half are the steady states (indicating feasibility) and second half the eigen values of Jacobian (indicating stability)
}
\description{
Tests the feasibility and stability of a vector of sampled parameters for the Bimler-Baker model
}
