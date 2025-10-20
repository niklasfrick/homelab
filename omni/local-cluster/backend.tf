terraform {
  cloud {

    organization = "949x"

    workspaces {
      name = "omni-local-workspace"
    }
  }
}
