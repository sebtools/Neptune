<!--- 1.0 Alpha 1 (Build 02) --->
<!--- Last Updated: 2010-10-11 --->
<!--- Created by Steve Bryant 2010-08-19 --->
<cfcomponent>

<cffunction name="init" access="public" returntype="any" output="no">
	<cfreturn This>
</cffunction>

<cffunction name="pluralize" access="public" returntype="string" output="false" hint="">
	<cfargument name="string" type="string" required="yes">
	<!--- http://owl.english.purdue.edu/handouts/grammar/g_spelnoun.html --->
	<cfset var result = arguments.string>
	
	<cfif Len(getSpecialPlural(result))>
		<cfset result = getSpecialPlural(result)>
	<cfelseif Right(result,1) EQ "y">
		<cfif isVowel(Mid(result,Len(result)-1,1))>
			<cfset result = result & "s">
		<cfelse>
			<cfset result = Left(result,Len(result)-1) & "ies">
		</cfif>
	<cfelseif Right(result,2) EQ "is">
		<cfset result = Left(result,Len(result)-2) & "es">
	<cfelseif isESPluralWord(result)>
		<cfset result = result & "es">
	<cfelseif Right(result,1) EQ "f">
		<cfset result = Left(result,Len(result)-1) & "ves">
	<cfelseif Right(result,2) EQ "fe">
		<cfset result = Left(result,Len(result)-2) & "ves">
	<cfelse>
		<cfset result = result & "s">
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="singularize" access="public" returntype="string" output="false" hint="">
	<cfargument name="string" type="string" required="yes">
	
	<cfset var result = arguments.string>
	
	<!--- Drop the "s" --->
	<cfif Right(result,1) EQ "s">
		<cfset result = Left(result,Len(result)-1)>
		<!--- If "y" was changed to "ie", change it back --->
		<cfif Right(result,2) EQ "ie" AND NOT FindNoCase(result,getWordsEndingIE())>
			<cfset result = Left(result,Len(result)-2) & "y">
		</cfif>
	</cfif>
	
	<!--- If "es" added to make plural, then drop the "e" as well --->
	<cfif Right(result,1) EQ "e" AND isESPluralWord(Left(result,Len(result)-1))>
		<cfset result = Left(result,Len(result)-1)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getSpecialPlural" access="private" returntype="string" output="false" hint="">
	<cfargument name="string" type="string" required="yes">
	
	<cfset var result = "">
	
	<cfswitch expression="#arguments.string#">
	<cfcase value="bass,cod,deer,elk,moose,pike,salmon,sheep,trout,tuna" delimiters=",">
		<cfset result = arguments.string>
	</cfcase>
	<cfcase value="child">
		<cfset result =  "Children">
	</cfcase>
	<cfcase value="foot">
		<cfset result =  "Feet">
	</cfcase>
	<cfcase value="goose">
		<cfset result =  "Geese">
	</cfcase>
	<cfcase value="man">
		<cfset result =  "Men">
	</cfcase>
	<cfcase value="mouse">
		<cfset result =  "Mice">
	</cfcase>
	<cfcase value="ox">
		<cfset result =  "Oxen">
	</cfcase>
	<cfcase value="tooth">
		<cfset result =  "Teeth">
	</cfcase>
	<cfcase value="woman">
		<cfset result =  "Women">
	</cfcase>
	</cfswitch>
	
	<!--- Adjust case --->
	<cfif NOT Compare(arguments.string,LCase(arguments.string))>
		<cfset result = LCase(result)>
	<cfelseif NOT Compare(arguments.string,UCase(arguments.string))>
		<cfset result = UCase(result)>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getWordsToAddES" access="private" returntype="string" output="false" hint="">
	<cfset var result = "">
<cfsavecontent variable="result"><cfoutput>
echo
embargo
hero
potato
tomato
torpedo
veto
</cfoutput></cfsavecontent>
	<cfreturn result>
</cffunction>

<cffunction name="isESPluralWord" access="private" returntype="boolean" output="false" hint="">
	<cfargument name="string" type="string" required="yes">
	
	<cfset result = false>
	
	<cfif
			Right(arguments.string,1) EQ "s"
		OR	Right(arguments.string,1) EQ "x"
		OR	Right(arguments.string,1) EQ "z"
		OR	Right(arguments.string,2) EQ "ch"
		OR	Right(arguments.string,2) EQ "sh"
		OR	FindNoCase(arguments.string,getWordsToAddES())
	>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="isVowel" access="private" returntype="any" output="false" hint="">
	<cfargument name="letter" type="string" required="yes">
	
	<cfset var vowels = "a,e,i,o,u,y">
	<cfset var result = false>
	
	<cfif ListFindNoCase(vowels,arguments.letter)>
		<cfset result = true>
	</cfif>
	
	<cfreturn result>
</cffunction>

<cffunction name="getWordsEndingIE" access="private" returntype="string" output="false" hint="">
	<cfset var result = "">
<cfsavecontent variable="result">
accidie
aerie
agacerie
aggie
alkie
amie
anomie
appleringie
assoilzie
auntie
awmrie
ayrie
baddie
baggie
bailie
baillie
banshie
barbie
barmie
batterie
bawtie
beanie
beardie
beastie
belie
bheestie
bhistie
biggie
bijouterie
bikie
billie
birdie
birkie
bittie
bizarrerie
blastie
blooie
blowie
bludie
boatie
boccie
bodgie
bogie
boiserie
bolletrie
bolshie
bonhomie
bonhommie
bonie
bonnie
bonxie
boobie
booboisie
boodie
boogie
bookie
booksie
bootie
bothie
bouderie
bougie
bourgeoisie
brasserie
brassie
brawlie
brickie
bridie
brie
brookie
brownie
bruilzie
brulyie
brulzie
brusquerie
buckie
budgie
bulletrie
bungie
bunjie
buppie
burdie
burnie
byrnie
cabbie
cabrie
caddie
cadie
calorie
camaraderie
cammie
camogie
camsteerie
candie
cannie
capercaillie
capercailzie
capernoitie
cardie
carnie
cattie
causerie
cavie
challie
chantie
chappie
charcuterie
charlie
charpie
cheapie
chewie
chinkie
chinoiserie
chippie
chookie
christie
chronaxie
chuckie
ciggie
civie
clamjamphrie
clavie
clippie
cludgie
cockaleekie
cockamamie
cockieleekie
coggie
cogie
collie
collieshangie
commie
conchie
conchiglie
condie
confiserie
confrerie
cookie
coolie
coontie
cootie
corbie
corrie
cosie
cossie
coterie
couthie
cowpie
cowrie
cozie
cramoisie
crappie
creepie
creperie
crombie
croppie
crosstie
crowdie
cruisie
crummie
crusie
cuddie
culchie
curie
curliewurlie
currie
curselarie
cutesie
cutie
daftie
darkie
dassie
dautie
dawtie
dearie
deawie
deccie
deepie
dependacie
dexie
dhootie
dhurrie
diablerie
dickie
didie
die
dinanderie
discandie
dixie
dobbie
dobie
dockmackie
doggie
dogie
dominie
donsie
doolie
doozie
doppie
dormie
dovekie
dovie
dowie
doxie
drappie
dricksie
druggie
duckie
duddie
durrie
ecurie
eerie
espieglerie
etourderie
etourdie
eyrie
faerie
falsie
fantasie
farcie
fedarie
federarie
feerie
feirie
feminie
ferlie
fie
fisnomie
flanerie
flooie
floosie
floozie
flossie
foedarie
fogie
folie
folkie
foodie
footie
footsie
forecaddie
forelie
forhooie
foudrie
freebie
friponnerie
frowie
fugie
fundie
gaberlunzie
gadgie
gaminerie
garvie
gaucherie
gaucie
gaudgie
gawsie
gendarmerie
genie
ghillie
ghoulie
gie
gilgie
gillie
gimmie
girlie
girnie
gladdie
glassie
goalie
goodie
goolie
goonie
grannie
greenie
gremmie
griesie
grinnie
grotesquerie
groupie
grumphie
grushie
grysie
guffie
guidwillie
gussie
gustie
gynie
gyppie
hackie
haddie
hankie
hawkie
hearie
heezie
heinie
hempie
hickie
hie
hippie
hirstie
histie
hoagie
hogtie
homie
honkie
hoodie
hoolie
hootanannie
hootenannie
hootnannie
hottie
howdie
howtowdie
humlie
humpie
hunkie
huskie
inconie
indie
insanie
intertie
jacksie
jacquerie
jalousie
japonaiserie
jarvie
jauntie
jeelie
jessie
jilgie
jimmie
jobbie
johnnie
jumbie
junkie
kaie
keavie
kebbie
keelie
kelpie
keltie
kewpie
kiddie
kiddiewinkie
kidgie
kierie
killie
killogie
kilocalorie
kilocurie
kiltie
knobkerrie
kookie
koppie
kylie
kyrie
laddie
laesie
laldie
lambie
lammie
lappie
lassie
leftie
leproserie
lezzie
librairie
lie
lingerie
lintie
lippie
loggie
logie
looie
loonie
louie
luckie
luggie
lungie
lunyie
luvvie
macchie
maconochie
magpie
malvesie
malvoisie
mamie
mammie
marqueterie
mashie
mattie
mavie
mealie
meanie
meemie
megacurie
meinie
menagerie
menyie
mesquinerie
metairie
microcurie
micromicrocurie
millicurie
minauderie
minnie
mislie
mobbie
mochie
moggie
mollie
mommie
monie
mosbolletjie
mossie
mousie
movie
moxie
mozzie
multicurie
muppie
muskie
nagapie
nannie
nappie
nartjie
necktie
nellie
newbie
newie
newsie
niaiserie
nie
nightie
nirlie
nitchie
niterie
nixie
nookie
nudie
obsequie
oldie
oorie
orangerie
organdie
ouglie
ourie
outlie
outvie
overlie
owrie
palmie
pantie
papeterie
pardie
parkie
parmacitie
passementerie
pastie
patisserie
patootie
pattie
peerie
penie
perdie
perentie
picocurie
pictarnie
pie
piggie
pigsnie
pinkie
pinnie
pirnie
pixie
plie
pliskie
plookie
plottie
ploukie
plumpie
plurisie
pockmantie
pollicie
polonie
pommie
pondokkie
pontie
popsie
porgie
porkpie
possie
postie
potpie
potsie
pourie
pousowdie
poussie
pownie
prairie
pratie
preemie
premie
prenzie
preppie
pressie
prezzie
primsie
prossie
prostie
puggie
pumie
punkie
purpie
puttie
pyxie
quashie
queenie
queynie
quickie
quinie
ramie
ramilie
ramillie
rancherie
randie
reallie
realtie
rechie
reechie
reekie
regie
relie
remanie
retie
reverie
revie
rhodie
riempie
rigwiddie
rigwoodie
roadie
roarie
roofie
rookie
roomie
rorie
rotchie
rotisserie
roughie
routhie
rudie
saltie
sannie
sansculotterie
sarnie
saulie
scaffie
scottie
scourie
scowrie
scrapie
scroggie
scroogie
scrunchie
seannachie
seecatchie
seigneurie
selkie
semie
sennachie
shanachie
sharpie
shavie
shawlie
sheenie
sheltie
shoogie
shortie
shrewdie
sickie
signeurie
silkie
sinfonie
sinopie
skellie
skivie
skollie
smartie
smoothie
smytrie
snottie
soapie
softie
sonsie
soogie
sortie
sosatie
sparkie
sparterie
spavie
specie
spie
spuilzie
spulyie
spulzie
spunkie
squaddie
staggie
starnie
stashie
steamie
steelie
stickie
stiddie
stie
stimie
stishie
stogie
stompie
stoolie
stooshie
stourie
stoutherie
stouthrie
studdie
stushie
stymie
subbie
sugarallie
sunkie
supercherie
superlie
surfie
suttletie
swabbie
swaggie
swankie
sweetie
swelchie
tackie
taddie
taillie
tailzie
talcarie
talkie
tammie
tangie
tantie
tapsalteerie
tapsieteerie
tassie
tatie
tattie
taupie
tawie
tawpie
tawtie
teachie
techie
teddie
tekkie
temperalitie
tentie
tie
tinnie
tirrivie
tittie
toastie
toonie
toorie
tootsie
tottie
toughie
tourie
toustie
toutie
towie
townie
tozie
tracasserie
trannie
trashtrie
trattorie
tremie
trickie
trie
troelie
troolie
truckie
tuilyie
tuilzie
tumshie
tushie
twinkie
tystie
ulyie
ulzie
underlie
unsonsie
untie
unwarie
uptie
valkyrie
vauntie
vawntie
veggie
vegie
vie
visie
visnomie
vizzie
vogie
waddie
waffie
walkyrie
wallie
wanchancie
waspie
wasterie
wastrie
wedgie
weenie
weepie
weirdie
wellie
wharfie
wheelie
whigmaleerie
whoopie
whoopsie
widdie
widgie
wienie
wifie
willie
woodie
woolie
yabbie
yachtie
yankie
yappie
yippie
yorkie
yowie
yumpie
yuppie
zombie
zowie
</cfsavecontent>
	<cfreturn result>
</cffunction>

</cfcomponent>