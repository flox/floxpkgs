{python3, ...}: python3.withPackages (ps: with ps; [
  kubernetes
  pytest
  allure-pytest
  pip
])
