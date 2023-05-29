variable "public_key_path" {
    type = string
    default = "/media/high-sparrow/Documents/studies/Master/DevOps/sideHustle/cluster/.vault/.cluster.pub"
}
variable "private_key_path" {
    type = string
    default = "/media/high-sparrow/Documents/studies/Master/DevOps/sideHustle/cluster/.vault/.cluster"
}
variable "vm_count" {
    type = number
    default = 5 # preferably an odd number above 3
}