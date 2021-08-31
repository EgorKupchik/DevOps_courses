
#!/bin/bash
CUR=""
if [ -n "$1" ]
then
  CUR=$1
else
  echo "Input currency name: "
  read CUR
fi
if [ "$CUR" == USD ]
then
  wget -q https://myfin.by/bank/kursy_valjut_nbrb/usd
  PAGE=`cat ./usd`
  PAGE=${PAGE#*1 USD в BYN*}
  PAGE=${PAGE#*</td><td>*}
  PAGE=${PAGE:0:1}
  echo "1 USD = $PAGE BUN"
  rm usd
elif [ "$CUR" == EUR ]
then
  wget -q https://myfin.by/bank/kursy_valjut_nbrb/eur
  PAGE=`cat ./eur`
  PAGE=${PAGE#*1 EUR в BYN*}
  PAGE=${PAGE#*</td><td>*}
  PAGE=${PAGE:0:1}
  echo "1 EUR = $PAGE BUN"
  rm eur
else
  echo "Unknow currency."
fi