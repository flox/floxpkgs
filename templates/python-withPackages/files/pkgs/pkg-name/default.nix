{python3}:
python3.withPackages (ps:
    with ps; [
      pandas
      pytorch
      tensorflow
    ])
