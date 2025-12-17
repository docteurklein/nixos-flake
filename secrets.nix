let keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYjyOT9I0Tpr72BeMjQbq7aP0Pj+octMDI5yDnn/BKy"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKUtE8KQ42TRqdC+H0N5kvwTzTIkF000Vm2u+82F1eeH"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1ajx+hPpEIkY4GZz5ObSoDo+uxB9dVcg+68Vup/LbK"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGBvRrUVaQKhWq15gi17mNBOM/p2IG8ao1l48C3Aja9+"
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQ8qx/fEfK+uEM2x1kEET1FkWZEjIYmdENBnqICJ+l2"
];
in {
  "secrets/wireless.age".publicKeys = keys;
  "secrets/wireless2.age".publicKeys = keys;
  "secrets/email.age".publicKeys = keys;
  "secrets/proton-auth-user-pass".publicKeys = keys;
  "secrets/proton-ca".publicKeys = keys;
  "secrets/proton-tls-crypt".publicKeys = keys;
}
