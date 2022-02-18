Download the private pem files from the Email and made the changes of the pem file path in terraform.tfvars file.
![Pem File Path Update Location](https://github.com/ramRK1/setu/blob/main/pem_file_path.png)

Run with a command like this:

```
terraform init
terraform plan (optional)
terraform apply -var-file=terraform.tfvars
```
