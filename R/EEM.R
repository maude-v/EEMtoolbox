#' @title Generation of model ensembles
#' @description
#' Generation of model ensembles based on generalized Lotka Volterra, and the other two model structures, generating algorithms include Approximate Bayesian Computation methods and standard ensemble ecosystem modelling (Baker et al., 2017)
#' @param interaction_matrix interaction signs matrix. If model is GLV or Gompertz it can be input as a single matrix of interactions or as a list of matrices defining lower and upper bounds for interaction terms lower first and upper second.     #if model is Bimler-Baker, the interaction_matrix has to be a list of two lists, the first list contains matrices defining lower and upper bounds of alphas, the second list contains matrices defining lower and upper bounds of betas
#' @param upper_bounds_growth_rate upper bound of growth rates. Input can be one number (same upper bound for all species) or a vector of growth rates upper bounds for each species. Default 5
#' @param lower_bounds_growth_rate lower bound of growth rates. Input can be one number (same lower bound for all species) or a vector of growth rates lower bounds for each species. Default 0
#' @param n_ensemble Number of desired ensemble members. Default to 5000
#' @param model model representing species interactions. Default "GLV" (Generalized Lotka Volterra). options include "Bimler-Baker", "Gompertz" and "customized"
#' @param algorithm algorithm used for sampling. Default "standard-EEM" (Baker et al, 2017), options include "SMC-EEM" (Vollert et al., 2023)
#' @param summ_func function calculating equilibrium points and real parts of the Jacobians eigenvalues to summarise ecosystem features. Default =summarise_ecosystem_features_GLV. Options include summarise_ecosystem_features_Baker (automatically chosen if model="Bimler-Baker") and summarise_ecosystem_features_Gompertz, (automatically chosen if model="Gompertz"). Needs to be defined if model="customized" chosen.
#' @param disc_func summary statistic (discrepancy measure). Default discrepancy_continuous_sum
#' @param sampler sampling function that generates random vectors from the joint prior distribution. Default EEMtoolbox::sampler function (uniform)
#' @param trans_f transform of prior parameter space to ensure unbounded support for MCMC sampling. Default EEMtoolbox::uniform_transform
#' @param trans_finv inverse of trans_f function. Default EEMtoolbox::uniform_transform_inverse
#' @param pdf joint probability density function. Default EEMtoolbox::uniform_pdf_transformed
#' @param mcmc_trials number of MCMC steps to try before selecting appropriate number. Default 10
#' @param dist_final target discrepancy threshold. Default 0. If zero, p_acc_min is used to determine stopping criteria.
#' @param a tuning parameter for adaptive selection of discrepancy threshold sequence. Defalut 0.6
#' @param c tuning parameter for choosing the number of MCMC iterations in move step. Default 0.01
#' @param p_acc_min minimum acceptable acceptance rate in the MCMC interations before exit. Default 0.0001
#' @param n_cores Number of cores desired to be used for sampling. Default set to 1 core (sequential sampling).
#' @param output_prior logical. If set to TRUE, algorithm returns prior distributions of parameters ensemble of parameters. Default FALSE
#' @param output_args logical. If set to TRUE, algorithm returns output from EEMtoolbox::args_function for this problem
#' @param output_discrepancy logical. If set to TRUE, algorithm returns discrepancy values
#' @param output_matrix logical. If set to TRUE, algorithm returns interaction matrix and growthrates
#' @examples
#' library(EEMtoolbox)
#' EEM(dingo_matrix) #automatically loads an example of interaction matrix as dingo_matrix
#' @return list: part_vals: ensemble of parameters, marginal distributions
#' @export
EEM <- function(interaction_matrix,
                upper_bounds_growth_rate=5,
                lower_bounds_growth_rate=0,
                n_ensemble=5000,
                model="GLV",
                algorithm="standard-EEM",
                summ_func=EEMtoolbox::summarise_ecosystem_features,
                disc_func=EEMtoolbox::discrepancy_continuous_sum,
                sampler=EEMtoolbox::uniform_sampler,
                trans_f=EEMtoolbox::uniform_transform,
                trans_finv=EEMtoolbox::uniform_transform_inverse,
                pdf=EEMtoolbox::uniform_pdf_transformed,
                mcmc_trials=10,
                dist_final=0,
                a=0.6,
                c=0.01,
                p_acc_min=0.0001,
                n_cores = 1L,
                output_prior=FALSE,
                output_args=FALSE,
                output_discrepancy=FALSE,
                output_matrix=TRUE
                ){
  # TESTS if inputs are correct ###########
  #interaction_matrix tests
  stopifnot(class(interaction_matrix)[1]=="matrix"|class(interaction_matrix)=="list")

  if (class(interaction_matrix)[1]=="matrix"){
    stopifnot(nrow(interaction_matrix)==ncol(interaction_matrix))
  } else {
    stopifnot(nrow(interaction_matrix[[1]])==ncol(interaction_matrix[[1]]))
    stopifnot(nrow(interaction_matrix[[2]])==ncol(interaction_matrix[[2]]))
    stopifnot(nrow(interaction_matrix[[1]])==nrow(interaction_matrix[[2]]))
  }

  #n_ensemble tests
  stopifnot(is.numeric(n_ensemble),
            (n_ensemble)>0)
  #model tests
  stopifnot(((model=="GLV")|(model=="Bimler-Baker")|(model=="Gompertz")|(model=="customized")))
  #algorithm
  stopifnot(((algorithm=="SMC-EEM")|(algorithm=="standard-EEM")))
  #summ_func
  stopifnot(class(summ_func)=="function")
  #disc_func
  stopifnot(class(disc_func)=="function")
  #sampler
  stopifnot(class(sampler)=="function")
  #trans_f
  stopifnot(class(trans_f)=="function")
  #trans_finv
  stopifnot(class(trans_finv)=="function")
  #pdf
  stopifnot(class(pdf)=="function")
  #dist_final
  stopifnot(is.numeric(dist_final),
            (dist_final)>=0)
  #a
  stopifnot(is.numeric(a),
            (a)>=0)
  #c
  stopifnot(is.numeric(c),
            (c)>=0)
  #p_acc_min
  stopifnot(is.numeric(p_acc_min),
            (p_acc_min)>=0)
  #output_prior
  stopifnot(class(output_prior)=="logical")
  #output_args
  stopifnot(class(output_args)=="logical")


  if (n_cores == 1L){
    print("The code will run on 1 cluster only (sequential).")
    print("Change the parameter 'n_cores' to parallelise code")
  }
  # Defining special arguments ####
  sim_args <- EEMtoolbox::args_function(interaction_matrix,
                                        upper_bounds_growth_rate,
                                        lower_bounds_growth_rate,
                                        model=model)

  ## RUNNING search algorithms####
  if (algorithm == "SMC-EEM"){
    print('Begin SMC-EEM search method')
    outputs <- EEMtoolbox::EEM_SMC_method(sim_args,
                                          summ_func,
                                          disc_func,
                                          sampler,
                                          trans_f,
                                          trans_finv,
                                          pdf,
                                          mcmc_trials,
                                          dist_final,
                                          a,
                                          c,
                                          p_acc_min,
                                          n_ensemble,
                                          n_cores)
  } else if ((algorithm=="standard-EEM")){
    print('Begin standard search method')
    outputs <- EEMtoolbox::EEM_standard_method(sim_args,
                                               summ_func,
                                               disc_func,
                                               sampler,
                                               trans_f,
                                               n_ensemble,
                                               n_cores)
  }
  if (output_matrix){
    output_function <- apply(outputs$part_vals[seq(n_ensemble),], 1, EEMtoolbox::reconstruct_matrix_growthrates,
                             sim_args=sim_args)
    return(output_function)
  } else {
    output_function <- list()
    output_function$part_vals <- outputs$part_vals[seq(n_ensemble),]
    output_function$sims <- outputs$sims
    if (output_prior){
      output_function$prior_sample <- outputs$prior_sample
    }
    if (output_discrepancy){
      output_function$part_s <- outputs$part_s[seq(n_ensemble)]
    }
    if (output_args){
      output_function$sim_args <- sim_args
    }
    return(output_function)
  }

}
