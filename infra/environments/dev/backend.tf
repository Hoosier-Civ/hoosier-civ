terraform {
  cloud {
    organization = "hoosierciv"

    workspaces {
      name = "hoosierciv-dev"
    }
  }
}
