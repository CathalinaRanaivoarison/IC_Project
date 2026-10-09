resource "aws_key_pair" "main" {
  key_name   = "ic-project-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
