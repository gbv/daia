#!/usr/local/php/bin/php
<?php
include_once 'pica2daia.php';

class PICA2DAIATest extends MyUnitTest {

    function staticMethods() {
        $doc = new DAIA_PICA(array('66666', '609368567', '614715318', '602032393', '609418300', '588945366'));
        
        $this->assertTrue($doc);
        // $this->assertEqual(...);
    }
}

/*
0609368567 = Magazin, ausgeliehen
0614715318 = bestellt EPN 1114481424
0602032393 = Lesesaal, ausleihbar verfügbar
0609418300 = mehrere Exemplare
588945366 = Magazin, ausleihbar verfügbar
Z 39.50: 609418300
  <datafield tag="900" ind1=" " ind2=" ">
      <subfield code="a">GBV</subfield>
      <subfield code="b">TUB Hamburg &lt;830&gt;</subfield>
      <subfield code="d">!TI! TIR-219</subfield>
      <subfield code="x">N</subfield>
      <subfield code="z">N</subfield>
      <subfield code="d">2835-8310</subfield>
      <subfield code="d">!TI! TIR-219</subfield>
      <subfield code="x">N</subfield>
  <subfield code="z">N</subfield>
      <subfield code="d">2835-8323</subfield>
      <subfield code="d">!LBS! TIR-219</subfield>
  <subfield code="e">5</subfield>
      <subfield code="x">L</subfield>
      <subfield code="z">LC</subfield>
    </datafield>
    Vermutung: Präsenzexemplare sind gekennzeichnet mit <subfield code="x">N</subfield> und/oder <subfield code="z">N</subfield>
Einzelexemplare 0609418300 URL https://katalog.b.tu-harburg.de/loan/DB=1/SET=1/TTL=13/REQ?EPN=1112114696&MTR=mon&BES=1&LOGIN=ANONYMOUS&REFERER=http%3A%2F%2Fvip28.b.tu-harburg.de%3A8080%2FDB%3D1%2FSET%3D1%2FTTL%3D13%2F%2FSHW%3FFRST%3D13&HOST_NAME=vip28.b.tu-harburg.de&HOST_PORT=8080&HOST_SCRIPT=&COOKIE=
Exemplarbestellung: https://katalog.b.tu-harburg.de/loan/DB=1/SET=3/TTL=1/REQ?EPN=1100539905&LOGIN=ANONYMOUS
Die EPNs finden sich im Marc-Output via Z39.50
reading room use only = Präsenzexemplar
Lendable Holding = Ausleihexemplar
available = verfügbar
lent = ausgeliehen
Einzelexemplarabfrage ergibt in HTML (Auszug!):
  <tr>
  <td nowrap align="center"><strong>-</strong></td>    ------------------------> Reservierungsmöglichkeit
  <td></td>
  <td class="table" nowrap>&nbsp; </td>
  <td></td>
  <td class="table" nowrap>&nbsp;Available, see Lehrbuchsammlung</td> ---------> Status (available/lent)
  <td></td>
  <td class="table" nowrap>&nbsp;Lehrbuchsammlung</td>  -----------------------> Standort
  <td></td>
  <td class="table" nowrap>&nbsp;0</td>                ------------------------> Anzahl Reservierungen
  </tr>

  <tr>
  <td nowrap align="center">
  <input type="radio" class="radio-button" name="VINFO" value="VBAR=830$26431297&TRC=D"></span></td>
  <td></td>
  <td class="table" nowrap>&nbsp; </td>
  <td></td>
  <td class="table" nowrap>&nbsp;Lent till 18-03-2010</td>
  <td></td>
  <td class="table" nowrap>&nbsp;Lehrbuchsammlung</td>
  <td></td>
  <td class="table" nowrap>&nbsp;0</td>
  </tr>


echo $doc->toXml();
*/
?>