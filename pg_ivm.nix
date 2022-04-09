{ lib, stdenv, fetchFromGitHub, postgresql_14 }:

stdenv.mkDerivation rec {
  pname = "pg_ivm";
  version = "1.0-alpha";

  #src = fetchFromGitHub {
  #  owner = "sraoss";
  #  repo = pname;
  #  rev = "v${version}";
  #  sha256 = "sha256-1AWLcMqJNdGqFRFB6B503v82xLBXRr2C3jUx1cJKJJk=";
  #};
  src = /home/florian/work/pg_ivm;

  buildInputs = [ postgresql_14 ];

  makeFlags = [ "USE_PGXS=1" ];

  installPhase = ''
    install -D -t $out/lib *.so
    install -D -t $out/share/postgresql/extension *.sql
    install -D -t $out/share/postgresql/extension *.control
  '';

  meta = with lib; {
    description = "Incremental View Maintenance as a postgres extension";
    homepage = "https://github.com/sraoss/pg_ivm/";
    license = licenses.postgresql;
    platforms = postgresql_14.meta.platforms;
    maintainers = [];
  };
}
