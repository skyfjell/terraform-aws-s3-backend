provider "aws" {
  region = "us-east-2"
}

variable "labels" {
  description = "Instance of Labels Module"
  type = object(
    {
      id   = optional(string)
      tags = optional(any, {})
    }
  )
  default = {}
}


variable "config_users" {
  description = "Additional User ARNs to Assume Role - !! Not recommended for production use !!"
  default     = {}

  type = object({
    enable = optional(bool, false)
    arns   = optional(list(string), [])
  })
}
