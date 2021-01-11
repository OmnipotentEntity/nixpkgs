{ lib, stdenv, fetchFromGitHub, last, exonerate, minia, python3Packages, bwa
, samtools, findutils, python }:

python3Packages.buildPythonApplication rec {
  pname = "tebreak";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "adamewing";
    repo = "tebreak";
    rev = version;
    sha256 = "13mgh775d8hkl340923lfwwm4r5ps70girn8d6wgfxzwzxylz8iz";
  };

  nativeBuildInputs = [ findutils python3Packages.cython ];
  propagatedBuildInputs = with python3Packages; [
    pysam
    scipy
    bx-python
    scikit-bio
  ];

  preConfigure = ''
    # patch the paths to all required software
    for f in $(find . -type f) ; do
      sed -i "s|'bwa'|'${bwa}/bin/bwa'|" $f
      sed -i "s|'minia'|'${minia}/bin/minia'|" $f
      sed -i "s|'exonerate'|'${exonerate}/bin/exonerate'|" $f
      sed -i "s|'samtools'|'${samtools}/bin/samtools'|" $f
      sed -i "s|'lastal'|'${last}/bin/lastal'|" $f
      sed -i "s|'lastdb'|'${last}/bin/lastdb'|" $f
    done
  '';

  checkPhase = ''
    $out/bin/tebreak -b test/data/example.ins.bam  -r test/data/Homo_sapiens_chr4_50000000-60000000_assembly19.fasta -p 4 --pickle test/example.pickle --detail_out test/example.tebreak.detail.out -i lib/teref.human.fa
    pushd test
    ${python.interpreter} checktest.py
  '';

  meta = with lib; {
    description = "Find and characterise transposable element insertions";
    homepage = "https://github.com/adamewing/tebreak";
    license = licenses.mit;
    maintainers = with maintainers; [ jbedo ];
    platforms = platforms.x86_64;
  };
}
