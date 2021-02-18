### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 343834a2-668e-11eb-2533-6fb672c854b2
begin
	using Pkg; Pkg.activate(@__DIR__)
	Pkg.instantiate(); Pkg.precompile()
	using CSV, DataFrames, DataFramesMeta, Query
	using Random, PlutoUI, Distributions
	using StatsBase, StatsPlots, GLM
	using Statistics, GeoStats, LossFunctions
	using Plots; gr(format="png")
end;

# ╔═╡ 7a2a5310-6690-11eb-3624-b1b66e094059
md"""
![geostats-logo](https://github.com/JuliaEarth/GeoStats.jl/blob/master/docs/src/assets/logo-text.svg?raw=true)

# Estimativa de Recursos em 3D

Instrutor: [Franco Naghetini](https://github.com/fnaghetini)
"""

# ╔═╡ 53ab7a10-6691-11eb-0a2c-0f0588db91ea
md"""
## Introdução

- Ainda que a computação científica tradicionalmente exija uma alta performance, muitos pesquisadores migraram para linguagens dinâmicas mais lentas (e.g. Python e R), muito em função da complexidade de linguagens estáticas mais rápidas, como C e Fortran.

- Nesse contexto, surge, em 2012, **Julia**, uma lingugem dinâmica cuja curva de aprendizado é tão alta quanto a do Python ou R e sua performance muito similar ao do Fortran ou C.

- Durante este treinamento, utilizaremos principalmente o pacote **GeoStats.jl**. Esse *framework* apresenta elevada performance para *workflows* voltados à Geoestatística e ao Aprendizado Geoestatístico, sendo mais rápido que o GSLIB e ainda sim de fácil aprendizado.

- Este treinamento visa demonstrar como uma rotina de estimativa de recursos tridimensional pode ser realizada, utilizando a linguagem **Julia** e, principalmente, o pacote **GeoStats.jl**.
"""

# ╔═╡ 9b1f7ff0-6ba9-11eb-3111-658a4692059c
html"""
	<h2>Agenda</h2>

	<a href="#importacao_dos_dados">
		<big>1. Importação dos Dados</big>
	</a><br><br>

	<a href="#geracao_dos_furos">
		<big>2. Geração dos Furos</big>
	</a><br><br>


	<a href="#descricao_e_limpeza_dos_dados">
		<big>3. Descrição & Limpeza dos Dados</big>
	</a><br><br>

	<a href="#AED">
		<big>4. Análise Exploratória dos Dados</big>
	</a><br><br>

	<a href="#preparacao_de_amostras">
		<big>5. Preparação de Amostras</big>
	</a><br><br>

	<a href="#vg_exp_model_vg">
		<big>6. Variografia Experimental & Modelagem Variográfica</big>
	</a><br><br>

	<a href="#estimativa">
		<big>7. Estimativa</big>
	</a><br><br>

	<a href="#validacao_da_estimativa">
		<big>8. Validação da Estimativa</big>
	</a><br><br>

	<a href="#exportacao">
		<big>9. Exportação dos Dados Estimados</big>
	</a><br><br>

	<a href="#recomendacoes">
		<big>10. Recomendações</big>
	</a><br><br>
	
	<a href="#referencias">
		<big>11. Referências</big>
	</a>
"""

# ╔═╡ c887b4c0-6691-11eb-15aa-c9293a19980c
md"""
## Fluxograma de Trabalho

O fluxograma deste treinamento é apresentado na Figura 1:
"""

# ╔═╡ d45e5ff2-6ba6-11eb-3574-6ff6768570d5
html"""
<p align="center">
	<img src="https://drive.google.com/drive/folders/1PNmmZL_jXpHPn29hvnNI7iFgdBK2SjZ7" alt="Figura_01">
</p>

<p align="center">
	<b>Figura 1</b>: Fluxograma de trabalho simplificado de Estimativa de Recursos.
</p>
"""

# ╔═╡ 34ef7a70-6972-11eb-324e-1d1ee39240fc
html"""<hr><hr>"""

# ╔═╡ 0ba43cd0-6ba9-11eb-2d22-c7fa0e0911cc
html"""
	<div id="importacao_dos_dados">

		<h2>1. Importação dos Dados</h2>

		<p>
			Neste roteiro, importaremos diretamente os dados de furos de sondagem.
		</p>

		<p>
			Abaixo, temos o dicionário de atributos dessa base de dados de sondagem: 		</p>

	</div>
"""

# ╔═╡ c61f62e0-6737-11eb-2ad9-7dab5d0bd0c5
html"""
<table>
	<tr>
		<th colspan="3" style="text-align: center;">
			<big>Dicionário de Atributos</big>
		</th>
	</tr>
	<tr>
		<th>Atributo</th>
		<th>Unidade</th>
		<th>Descrição</th>
	</tr>
	<tr>
		<td><b>hole_id</b></td>
		<td style="text-align: center;">-</td>
		<td>
			Identificador do furo
		</td>
	</tr>
	<tr>
		<td><b>east</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Coordenada X do centroide da amostra
		</td>
	</tr>
	<tr>
		<td><b>north</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Coordenada Y do centroide da amostra
		</td>
	</tr>
	<tr>
		<td><b>elevation</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Coordenada Z do centroide da amostra
		</td>
	</tr>
	<tr>
		<td><b>from</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Início do intervalo amostral
		</td>
	</tr>
	<tr>
		<td><b>to</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Final do intervalo amostral
		</td>
	</tr>
	<tr>
		<td><b>final_depth</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Profundidade final do furo
		</td>
	</tr>
	<tr>
		<td><b>sample_length</b></td>
		<td style="text-align: center;">m</td>
		<td>
			Tamanho da amostra
		</td>
	</tr>
	<tr>
		<td><b>dip_direction</b></td>
		<td style="text-align: center;">°</td>
		<td>
			Sentido de mergulho da amostra
		</td>
	</tr>
	<tr>
		<td><b>dip</b></td>
		<td style="text-align: center;">°</td>
		<td>
			Ângulo de mergulho da amostra
		</td>
	</tr>
	<tr>
		<td><b>cu_perc</b></td>
		<td style="text-align: center;">%</td>
		<td>
			Teor de Cu da amostra
		</td>
	</tr>
	<tr>
		<td><b>lithology</b></td>
		<td style="text-align: center;">-</td>
		<td>
			Litotipos
		</td>
	</tr>
	<tr>
		<td><b>hole_radius</b></td>
		<td style="text-align: center;">-</td>
		<td>
			Raio da amostra
		</td>
	</tr>
</table>
"""

# ╔═╡ 889f92f0-673c-11eb-0364-f54810567214
begin
	df = CSV.File("data/drillholes.csv") |> DataFrame
	first(df, 5)
end

# ╔═╡ c8ebce50-6971-11eb-01fd-adf537723fb9
html"""<hr><hr>"""

# ╔═╡ 71408b30-6e4b-11eb-1c70-e746d0ffa359
html"""
	<div id="geracao_dos_furos">

		<h2>2. Geração dos Furos</h2>

	</div>
"""

# ╔═╡ a11acb9e-699a-11eb-38ee-45c0f768a1a3
md"""
É comum que os dados de sondagem sejam apresentados através de um conjunto de três tabelas distintas, relacionadas entre si por um campo-chave (Figura 2).

Esse campo-chave que interliga as três tabelas é o identificador dos furos (comumente chamado de `BHID` ou `HOLEID`).

- A tabela **Collar** traz consigo, obrigatoriamente, informações das coordenadas de boca dos furos e de profundidade final de cada furo e, opcionalmente, a data de finalização dos furos e o método de aquisição das coordenadas.

- A tabela **Survey** apresenta informações de perfilagem, ou seja, de orientação dos furos (dip direction/dip).

- A tabela **Assay** contém dados de teores, densidade, litologia, zonas mineraizadas e parâmetros geomecânicos agrupados por intervalos amostrais.

"""

# ╔═╡ 33e94850-6e44-11eb-1d23-1bcec1d9ab94
html"""
<p align="center">
	<img src="Caminho/Da/Figura 2.png" alt="Figura_02">
</p>

<p align="center">
	<b>Figura 2</b>: Tabelas de collar, assay e survey. Note que elas se encontram relacionadas entre si pelo campo-chave BHID.
</p>
"""

# ╔═╡ 02996b20-70c1-11eb-2434-a592600949de
md"""

A geração dos furos, a partir dessas tabelas, pode ser feita por meio da função `drillhole()`, disponível na biblioteca `DrillHoles.jl`.

- Importação das tabelas de collar, assays e survey no ambiente Julia:

> **collar = Collar(file="C:/collar.csv", holeid=:BHID, x=:X, y=:Y, z=:Z)**

> **survey = Survey(file="C:/survey.csv", holeid=:BHID, at=:AT, azm=:AZM, dip=:DIP)**

> **assay  = Interval(file="C:/assay.csv", holeid=:BHID, from=:FROM, to=:TO)**

> **litho  = Interval(file="C:/litho.csv", holeid=:BHID, from=:FROM, to=:TO)**

- Geração dos furos:

> **dh = drillhole(collar, survey, [assay, litho])**

- Ao final da geração dos furos, são criados quatro objetos:

    - `dh.table`: tabela dos furos de sondagem.

    - `dh.trace`: arquivo com as coordenadas das profundidades de perfilagem.

    - `dh.pars`: nomes das colunas.

    - `dh.warns`: tabela que contém erros e avisos identificados durante o processo de *desurveying*.

"""

# ╔═╡ 9394a8a0-699c-11eb-2852-f5f450a869b8
html"""<hr><hr>"""

# ╔═╡ f54ccf10-6748-11eb-20b2-418a5d38f613
html"""
	<div id="descricao_e_limpeza_dos_dados">

		<h2>3. Descrição & Limpeza dos Dados</h2>

	</div>
"""

# ╔═╡ 71e44170-6749-11eb-2c46-ed3e09bbba6b
md"""
###### Sumário estatístico

- O banco de dados consiste em conjunto de 127 furos realizados durante uma campanha de sondagem em um depósito fictício de Cu Pórfiro.

- O depósito apresenta as seguintes dimensões aproximadas:
    + 780 m em X.
    + 600 m em Y.
    + 250 m em Z.
- A distância média entre furos vizinhos é de aproximadamente 35 m.

- 50 valores faltantes da variável `cu_perc`.
"""

# ╔═╡ 93d7ecfe-6748-11eb-2b92-05ad9da17816
describe(df)

# ╔═╡ 89801c00-6749-11eb-2150-83ca5080cfa9
md"""
###### Renomeando colunas
"""

# ╔═╡ 97126210-6749-11eb-1458-f3b233eeccfd
begin
	dh = df |> @rename(:hole_id => :BHID,
			  :east => :X,
			  :north => :Y,
			  :elevation => :Z,
			  :from => :FROM,
			  :to => :TO,
			  :final_depth => :ENDDEPTH,
			  :sample_length => :LENGTH,
			  :dip_direction => :A0,
			  :dip => :B0,
			  :cu_perc => :CU,
			  :lithology => :LITH,
			  :hole_radius => :RADIUS) |> DataFrame
	first(dh, 5)
end

# ╔═╡ 1e5cb230-6753-11eb-2c5a-47635839ae47
md"""
###### Remoção de valores faltantes de Cu
"""

# ╔═╡ 42060790-6753-11eb-2674-6d09047846d7
begin
	dropmissing!(dh, disallowmissing=true)
	
	describe(dh)
end

# ╔═╡ 4349cb70-6972-11eb-3b68-071d7b8e4af7
html"""<hr><hr>"""

# ╔═╡ d6c57740-6e4b-11eb-351f-cd78f069bea7
html"""
	<div id="AED">

		<h2>4. Análise Exploratória dos Dados (AED)</h2>

	</div>
"""

# ╔═╡ 7fb29332-6756-11eb-23df-fda7421f6559
md"""

A Análise Exploratória dos Dados é uma das etapas mais cruciais deste fluxo de trabalho. Em essência, ela consiste em sumarizar, descrever e obter _insights_ a partir do banco de dados.

A AED antecede a variografia e, consequentemente, a estimativa propriamente dita e deve e objetiva trasnformar dados em informações. Muitos estatísticos definem esta etapa como:

            "A arte de torturar os dados até que eles confessem as informações."

A AED será dividida em três subetapas:

- **Descrição Univariada**

- **Descrição Bivariada**

- **Descrição Espacial**

Ao final, sumarizaremos as informações e _insights_ obtidos a partir da AED.
"""

# ╔═╡ ef3ef810-699f-11eb-342d-b97fb146d03f
html"""<hr>"""

# ╔═╡ e16b7bc0-6759-11eb-292c-e15b4a1d845e
md"""
### Descrição Univariada
"""

# ╔═╡ c92611c0-67bc-11eb-1dad-f998543a00e9
md"""
#### Cobre (CU)
"""

# ╔═╡ 1af5b540-675a-11eb-0cec-bf86a16706e2
begin
	X̅ = mean(dh.CU)
	S² = var(dh.CU)
	S = std(dh.CU)
	Cᵥ = variation(dh.CU)
	IQR = iqr(dh.CU)
	q = quantile(dh.CU, [0.1, 0.25, 0.50, 0.75, 0.90])
	Skew = skewness(dh.CU)
	Kurt = kurtosis(dh.CU)
	
	sum_cu = DataFrame(Variável=:CU, X̅=round(X̅,digits=2),
		S²=round(S²,digits=2), S=round(S,digits=2), Cᵥ=round(Cᵥ,digits=2),
		IQR=IQR, P10=q[1], P25=q[2], P50=q[3], P75=q[4], P90=q[5],
		Skew=round(Skew,digits=2), Kurt=round(Kurt,digits=2))
end

# ╔═╡ d949bed0-67c1-11eb-1598-d192d8f06f1e
begin
	dh |> @df histogram(:CU, xlabel="Cu (%)", ylabel="Frequência Absoluta",
				  color="darkgoldenrod1", legend=true, label=false, alpha=0.65)
	
	vline!([X̅], c="red", ls=:solid, label="X̅")
	vline!([q[3]], c="green", ls=:solid, label="P50")
	vline!([q[1]], c="black", ls=:dashdot, label="P10")
	vline!([q[5]], c="black", ls=:dashdot, label="P90")
	
end

# ╔═╡ 0d473630-67be-11eb-36ea-dfe7ddc63b10
md"""
- A média do Cu é igual a 0.86%.

- O coeficiente de variação do Cu é de aproximadamente 50%.

- A princípio, os _lowgrades_ do depósito correspondem a amostras ≤ 0.45%.

- A princípio, os _highgrades_ do depósito correspondem a amostras > 1.37%.

- Como X̅ > P50, Skew > 0 e tem-se cauda alongada à direita, a distribuição da variável Cu é assimétrica positiva. Isso faz sentido, uma vez que o Cu é tipicamente um elemento menor.

- Como Kurt(excessiva) > 0, a distribuição do Cu é leptocúrtica, ou seja, as caudas são mais densas do que caudas de uma Distribuição Gaussiana (seja ela padrão ou não).
"""

# ╔═╡ ee463560-67cc-11eb-27ec-a77d3f1d7fe9
md"""
#### Litologia (LITH)
"""

# ╔═╡ 00479350-68a7-11eb-0b15-770340616ebd
html"""
<table>
	<tr>
		<th>Sigla</th>
		<th>Litotipo</th>
	</tr>
	<tr>
		<td style="text-align: center;">TnP</td>
		<td>Tonalito Pórfiro</td>
	</tr>
	<tr>
		<td style="text-align: center;">GnP</td>
		<td>Granodiorito Pórfiro</td>
	</tr>
	<tr>
		<td style="text-align: center;">MzP</td>
		<td>Monzonito Pórfiro</td>
	</tr>
"""

# ╔═╡ fe1cc620-67cc-11eb-20b7-1b974ff48ae4
lito = dh |>
	@groupby(_.LITH) |>
	@map({Litologia=key(_), Contagem=length(_)}) |>
	DataFrame

# ╔═╡ fdaadbc0-681f-11eb-290c-e5a47afa6b1d
bar(lito[:,:Litologia], lito[:,:Contagem], legend=false,
		ylabel="Contagem", color=:pink1, alpha=0.65)

# ╔═╡ 16836ed0-694e-11eb-22f6-11f66381b342
md"""
- O banco de dados é composto por três litotipos distintos: Tonalito Pórfiro, Granodiorito Pórfiro e Monzonito Pórfiro.

- As três litologias apresentam número de ocorrências muito semelhantes.
"""

# ╔═╡ 9b3c0620-681b-11eb-2039-0b90437c77b5
md"""
#### Tamanho da amostra (LENGTH)
"""

# ╔═╡ 4f45323e-681c-11eb-337e-9f57be991302
begin	
	sum_sup = DataFrame(Minₜ = minimum(dh.LENGTH),
			            Maxₜ = maximum(dh.LENGTH), 
			  			X̅ₜ = round(mean(dh.LENGTH), digits=2),
			  			P50ₜ = median(dh.LENGTH),
			  			Sₜ = round(std(dh.LENGTH), digits=2),
			 			CVₜ = round(variation(dh.LENGTH), digits=2),
			  			Skewₜ = round(skewness(dh.LENGTH), digits=2))
end

# ╔═╡ 3350fa10-681c-11eb-1843-f72bb73520c7
begin
	dh |> @df histogram(:LENGTH, xlabel="Suporte Amostral (m)",
		ylabel="Frequência Absoluta", color="gray90",
		legend=:topleft, label=false, alpha=0.75)
	
	vline!([sum_sup.X̅ₜ], c="red", ls=:solid, label="X̅")
	vline!([sum_sup.P50ₜ], c="green", ls=:solid, label="P50")
	
end

# ╔═╡ b24a4730-694e-11eb-22e8-8becd4e846e8
md"""

- Grande parte das amostras apresenta um comprimento igual a 5 m.

- A variável `LENGTH` apresenta uma distribuição assimétrica negativa.

- A mediana de `LENGTH` é ligeiramente maior que a média.

- O máximo de `LENGTH` é igual à sua mediana.

- O mínimo de `LENGTH` é igual à metade da mediana.

- A variável `LENGTH` apresenta baixa variabilidade.
"""

# ╔═╡ f3e973d0-681f-11eb-2916-87436e59189a
md"""
#### Sentido de mergulho (A0)
"""

# ╔═╡ 6a4ebf80-6820-11eb-0239-dfefc4c9cbbd
begin
	qₐ = quantile(dh.A0, [0.25, 0.75])

	sum_azi = DataFrame(X̅ₐ = round(mean(dh.A0), digits=2),
						P25ₐ = round(qₐ[1], digits=2),
						P50ₐ = round(median(dh.A0), digits=2),
						P75ₐ = round(qₐ[2], digits=2),
						Minₐ = round(minimum(dh.A0), digits=2),
						Maxₐ = round(maximum(dh.A0), digits=2))
end

# ╔═╡ 2ca51d40-6821-11eb-3d3d-813ebfb191c2
begin
	a = dh |> @df histogram(:A0, xlabel="Azimute (°)",
		ylabel="Frequência Absoluta", color="gray90",
		legend=:topleft, label=false, bins=25, alpha=0.75)
	
	vline!([sum_azi.X̅ₐ], c="red", ls=:solid, label="X̅")
	vline!([sum_azi.P50ₐ], c="green", ls=:solid, label="P50")
end

# ╔═╡ e0503da0-694f-11eb-040e-79eb6bae7f94
md"""
- A distribuição de `A0` é levemente assimétrica negativa.

- A média de `A0` é de aproximadamente 150°.

- Grande parte dos valores de `A0` encontram-se entre 140° e 160°.
"""

# ╔═╡ 9ac58ee0-6821-11eb-23ba-afdc622aea47
md"""
#### Ângulo de mergulho (B0)
"""

# ╔═╡ af5b5560-6821-11eb-1027-4d4eff83fb49
begin	
	qₚ = quantile(dh.B0, [0.25, 0.75])

	sum_dip = DataFrame(X̅ₚ = round(mean(dh.B0), digits=2),
						P25ₚ = round(qₚ[1], digits=2),
						P50ₚ = round(median(dh.B0), digits=2),
						P75ₚ = round(qₚ[2], digits=2),
						Minₚ = round(minimum(dh.B0), digits=2),
						Maxₚ = round(maximum(dh.B0), digits=2))
end

# ╔═╡ aeff2ba0-6821-11eb-098b-4745596c78b0
begin 	
	dh |> @df histogram(:B0, xlabel="Dip (°)",
			ylabel="Frequência Absoluta", color="gray90",
			label=false, bins=50, alpha=0.75)
	
	vline!([sum_dip.X̅ₚ], c="red", ls=:solid, label="X̅")
	vline!([sum_dip.P50ₚ], c="green", ls=:solid, label="P50")
end

# ╔═╡ 34dbeae0-6950-11eb-3ce0-39769f66899f
md"""
- A média de `B0` é igual à sua mediana e, portanto, a distribuição desta variável é simétrica.

- Grande parte dos valores de `B0` estão em torno de 55° ± 20°.

- Existe um pequeno conjunto de valores que apresentam `B0 = 90°` (furos verticais).
"""

# ╔═╡ aaff8c20-6970-11eb-0c6a-7b65b7eb60af
html"""<hr>"""

# ╔═╡ 9324f930-6823-11eb-2801-6b6a6e9c932e
md"""
### Descrição Bivariada
"""

# ╔═╡ 3f187220-6893-11eb-3400-fdceb2722f8f
md"""
#### Cobre x Litologia (CU x LITH)
"""

# ╔═╡ 5f0452d0-696e-11eb-0153-6d79a5b2c877
md"""###### Sumário estatístico"""

# ╔═╡ 9d435950-6893-11eb-17b4-137a29920220
dh |> @groupby(_.LITH) |>
						@map({Litologia_Cu=key(_),
							  X̅ₗ=round(mean(_.CU), digits=2),
							  Minₗ=round(minimum(_.CU), digits=2),
							  Maxₗ=round(maximum(_.CU), digits=2),
							  S²ₗ=round(var(_.CU), digits=2),
							  Sₗ=round(std(_.CU), digits=2),
							  CVₗ=round(variation(_.CU), digits=2),
							  P10ₗ=round(quantile(_.CU, [0.10])[1], digits=2),
							  P25ₗ=round(quantile(_.CU, [0.25])[1], digits=2),
							  P50ₗ=round(median(_.CU), digits=2),
							  P75ₗ=round(quantile(_.CU, [0.75])[1], digits=2),
							  P90ₗ=round(quantile(_.CU, [0.90])[1], digits=2)})

# ╔═╡ 7b5acf40-696e-11eb-3622-b34aac8e92a9
md"""###### Histograma"""

# ╔═╡ 5531f270-6893-11eb-0f9c-6f75892042bb
dh |> @df histogram(:CU, group=:LITH, 
					xlabel="Cu (%)",
					ylabel="Frequência Absoluta",
					alpha=0.75)

# ╔═╡ 86b3ee32-696e-11eb-37dd-552fe42a39d6
md"""###### Boxplot & Violin Plot"""

# ╔═╡ 790998e0-6895-11eb-11ee-315f5809f7ec
begin
	@df dh violin(:LITH, :CU, group=:LITH)
	@df dh boxplot!(:LITH, :CU, color="gray90",
					alpha=0.55, ylabel="Cu (%)", label=false)
end

# ╔═╡ a2adf2be-696e-11eb-0461-073da1fd9940
md"""###### Q-Q Plot"""

# ╔═╡ 16a9abd0-689b-11eb-21e8-59aa875336db
begin
	GnP = dh |> @filter(_.LITH == "GnP") |> DataFrame
	MzP = dh |> @filter(_.LITH == "MzP") |> DataFrame
	TnP = dh |> @filter(_.LITH == "TnP") |> DataFrame
	
	P90_GnP = quantile(GnP.CU, [0.9])[1]
	P90_MzP = quantile(MzP.CU, [0.9])[1]
	P90_TnP = quantile(TnP.CU, [0.9])[1]
	
	qq₁ = qqplot(GnP.CU, MzP.CU,
				 xlabel="Cu (GnP)", ylabel="Cu (MzP)",
				 color="red", label=false)
	hline!([P90_MzP], color="gray", ls=:dash, label=false)
	vline!([P90_GnP], color="gray", ls=:dash, label="P90")
	
	
	qq₂ = qqplot(GnP.CU, TnP.CU,
				 xlabel="Cu (GnP)", ylabel="Cu (TnP)",
				 color="deepskyblue", label=false)
	
	hline!([P90_TnP], color="gray", ls=:dash, label=false)
	vline!([P90_GnP], color="gray", ls=:dash, label="P90")
	
	qq₃ = qqplot(MzP.CU, TnP.CU,
				 xlabel="Cu (MzP)", ylabel="Cu (TnP)",
				 color="green", label=false)
	hline!([P90_TnP], color="gray", ls=:dash, label=false)
	vline!([P90_MzP], color="gray", ls=:dash, label="P90")

	plot(qq₁, qq₂, qq₃, legend=:topleft)
end

# ╔═╡ b8d61910-696e-11eb-22b5-fd8a6637ada1
md"""
- Nota-se que o Monzonito Pórfiro (MzP) é o litotipo que apresenta maiores média e variabilidade.

- Embora as três distribuições sejam assimétricas positivas e de certa forma similares entre si, há diferenças em suas médias e dispersões.

- As distribuições de Cu associadas aos litotipos Monzonito Pórfiro (MzP) e Granodiorito Pórfiro (GnP) aparentam ser muito similares entre si.

- A distribuição do litotipo Tonalito Pórfiro (TnP) é muito distinta das demais, apresentando média e dispersão inferiores.

- Nota-se que, em geral, o aumento da média é acompanhado pelo o aumento da variabilidade do Cu.
"""

# ╔═╡ 99964d70-6970-11eb-3f68-9193cb05bde5
html"""<hr>"""

# ╔═╡ 15168ae0-68aa-11eb-1169-03ba57fba5ee
md"""
### Descrição Espacial
"""

# ╔═╡ 3ef3a2b0-68ac-11eb-11d4-9f86c0bc55eb
md"""
#### Visualização dos Furos por Litologia
"""

# ╔═╡ c74d81b2-68ef-11eb-2e46-c15d3dc8417d
md"""
Rotação em Z: $(@bind α₁ Slider(0:10:90, default=30, show_value=true))°

Rotação em X: $(@bind β₁ Slider(0:10:90, default=30, show_value=true))°
"""

# ╔═╡ 6eaf66d0-68aa-11eb-3447-8778ee384000
dh |> @df scatter(:X, :Y, :Z, group=:LITH, marker=:circle,
				  markersize=4, camera=(α₁,β₁),
				  xlabel="X", ylabel="Y", zlabel="Z")

# ╔═╡ d0b39e50-68af-11eb-0f57-27c2eda82e04
md"""
#### Visualização dos Teores
"""

# ╔═╡ 9eb1d8a0-68ef-11eb-2f89-094b93fe487b
md"""
Rotação em Z: $(@bind αₜ Slider(0:10:90, default=30, show_value=true))°

Rotação em X: $(@bind βₜ Slider(0:10:90, default=30, show_value=true))°
"""

# ╔═╡ dea62cce-68af-11eb-38f5-3163f2812fdf
dh |> @df scatter(:X, :Y, :Z, marker_z=:CU, marker=:circle,
				  markersize=4, camera=(αₜ,βₜ),
				  xlabel="X", ylabel="Y", zlabel="Z",
				  legend=false, colorbar=true, c=:viridis)

# ╔═╡ 8ab36b92-68ac-11eb-3d40-2f2b68531855
md"""
#### Visualização dos Highgrades e Lowgrades
"""

# ╔═╡ 5b177af0-68ef-11eb-2ea4-f59094b4fa51
md"""
Rotação em Z: $(@bind α₂ Slider(0:10:90, default=30, show_value=true))°

Rotação em X: $(@bind β₂ Slider(0:10:90, default=30, show_value=true))°
"""

# ╔═╡ bbc9fd60-68ad-11eb-2719-c9bfcc5d96c3
begin	
	hg = dh |> @filter(_.CU > q[5])
	lg = dh |> @filter(_.CU ≤ q[1])

	@df dh scatter(:X, :Y, :Z, marker=:circle, markersize=4,
					color="gray95",xlabel="X", markeralpha=0.5,
					ylabel="Y", zlabel="Z", label=false)
	
	@df hg scatter!(:X, :Y, :Z, marker=:circle, markersize=4,
					camera=(α₂,β₂),color="red", label="Highgrades")

	@df lg scatter!(:X, :Y, :Z, marker=:circle, markersize=4,
					legend=:topright, color="deepskyblue", label="Lowgrades")
	
end

# ╔═╡ 0cb77fc0-6973-11eb-2eca-017927d15a8e
md"""
- As regiões onde ocorrem os _high grades_ aparentam mostrar maior densidade amostral.

- Os valores de _low grade_ tendem a se situarem em porções de densidade amostral baixa.

- As amostras apresentam-se ligeiramente agrupadas preferencialmente na porção SE do depósito.
"""

# ╔═╡ 4f0f1cf0-68b2-11eb-08d8-e32e50cc5708
md"""
#### Georreferenciamento

- Neste contexto, georreferenciar os dados consiste em informar quais atributos devem ser tratados como coordenadas e quais devem ser entendidos com variáveis.

- Quando se georreferncia um determinado conjunto de dados, ele passa a ser tratado no código como um objeto espacial.

- Um objeto espacial apresenta um **domínio (domain)**, ou seja, suas informações espaciais (coordenadas) e **valores (values)**, ou seja, suas variáveis.

- No caso, iremos georreferenciar o arquivo de furos, de modo que as coordenadas `X`, `Y` e `Z` serão passadas como domínio e a variável `CU` será entendida como valor.
"""

# ╔═╡ edbbb020-68b2-11eb-3797-5f84caa35b9e
begin
	dh_temp = dh[:,[:X,:Y,:Z,:CU]]
	
	dh_georef = georef(dh_temp, (:X,:Y,:Z))
end

# ╔═╡ f14a3690-698d-11eb-0a3f-3f28c067f035
domain(dh_georef)

# ╔═╡ f243ffe0-698d-11eb-1c71-05f50abc7fd4
values(dh_georef)

# ╔═╡ 3896bbe0-6943-11eb-3cbd-adbb2c7c0026
md"""
#### Desagrupamento Amostral (*Declustering*)
"""

# ╔═╡ 8880f180-6f0a-11eb-1fb4-d5354b342647
md"""
##### Introdução

É muito comum, na mineração, que regiões "mais ricas" de um depósito sejam mais amostradas do que suas porções "mais pobres" (Figura 3). Essa situação se justifica pelo fato de a sondagem ser um procedimento de elevado custo e, nesse sentido, é mais coerente que amostremos mais as regiões mais promissoras do depósito.

A **Teoria da Amostragem** deixa claro que a amostragem de um fenômeno (e.g. mineralização de Cu) deve ser **representativa**. Em outras palavras:

- *"Uma amostra é representativa, quando qualquer parte do todo (população/depósito) tem iguais chances de ser amostrada. Se alguma parte for favorecida/desfavorecida na amostragem, a amostra não é representativa"*.

Nesse sentido, como **frequentemente há um agrupamento amostral preferencial nas porções ricas dos depósitos**, podemos dizer que a **amostragem de depósitos minerais não é representativa**. Dessa maneira, como temos uma amostragem sistematicamente não representativa, teremos uma estimativa sistematicamente não fiel à realidade do depósito.

Uma **forma de mitigar esse viés amostral intrínseco à indústria da mineração** é a utilização de **técnicas de declusterização**.

Assim, existem duas técnicas de declusterização principais:
- **Método da Poligonal**.
- **Método das Células Móveis**.

Neste treinamento, optaremos pelo Método da Poligonal.
"""

# ╔═╡ 4a962ac0-6f0f-11eb-375f-61b6de91bebe
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_03">
</p>

<p align="center">
	<b>Figura 3</b>: Exemplo de agrupamento amostral preferencial nas porções de <i>highgrade</i>.
</p>
"""

# ╔═╡ 829a6080-6f0f-11eb-1d3c-b9d97d41a225
md"""
##### Declusterização pelo Método da Poligonal

O **Método da Poligonal** visa encontrar o poliedro (3D) de influência, de modo que o peso atribuído a cada unidade amostral é função dos volumes desses poliedros.

Esse método pode ser conduzido de duas formas distintas:

- Criação de um *grid* com blocos pequenos seguida pela estimação via Vizinho Mais Próximo (*Nearest Neighbor*).

- Definição de poliedros de Voronoi, em que cada amostra é considerada como centroide de um poliedro de influência. O valor dessa amostra representa todo o volume do seu respectivo poliedro.

Esses poliedros são construídos a partir das medianas das distâncias entre pares de amostras. Nesse sentido, qualquer ponto situado dentro de um determinado poliedro, cujo centroide é uma amostra *i*, estará mais próximo dessa amostra *i* do que de qualquer outra amostra.

Portanto, regiões com maior agrupamento amostral preferencial apresentarão poliedros de menor volume, ao passo que regiões de baixa densidade amostral conterão poliedros de maior volume (Figura 4).

Nesse sentido, os pesos atribuídos a cada amostra são diretamente proporcionais ao volume apresentado pelo seu poliedro de influência correspondente.

A equação da média declusterizada (μ̂) é representada por:

```math
μ̂ = \frac {1}{A} \sum_{i=1}^{n} wᵢ.Z(uᵢ)
```

- A: somatório de todos os volumes dos poliedros de Voronoi definidos.

- wᵢ: volume do poliedro de Voronoi centrado na posição uᵢ.

- Z(uᵢ): valor da variável de interesse na posição uᵢ.
"""

# ╔═╡ f882c1c0-6f14-11eb-0570-fb2d9a4da191
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_04">
</p>

<p align="center">
	<b>Figura 4</b>: Exemplo de construção de polígonos de Voronoi para um contexto bidimensional (Pyrcz <i>et al.</i>, 2006).
</p>
"""

# ╔═╡ fb1a2040-6947-11eb-209c-75ac9ef76a37
md"""
###### Sumário estatístico Cu (original/clusterizado)
"""

# ╔═╡ 17437230-6948-11eb-3cee-59ff37e5dc2f
sum_cu[:, [:Variável, :X̅, :S², :S, :P10, :P25, :P50, :P75, :P90]]

# ╔═╡ 2da964d0-6948-11eb-3297-0d38b3f76f6e
md"""
###### Sumário estatístico Cu (declusterizado)
"""

# ╔═╡ 82c2ec70-6943-11eb-0208-a3287d596807
begin
	q_dec = quantile(dh_georef, :CU, [0.1, 0.25, 0.5, 0.75, 0.9])
	
	sum_dec = DataFrame(
							Variável = :CU_dec,
							X̅ = round(mean(dh_georef, :CU), digits=2),
							S² = round(var(dh_georef, :CU), digits=2),
							S = round(sqrt(var(dh_georef, :CU)), digits=2),
							P10 = q_dec[1],
							P25 = q_dec[2],
							P50 = q_dec[3],
							P75 = q_dec[4],
							P90 = q_dec[5]
						  )
end

# ╔═╡ dfb2a240-6948-11eb-2b98-f9b70c96340b
md"""
###### Histograma declusterizado
"""

# ╔═╡ ae093bc0-6946-11eb-2ffd-374f53bedf86
begin
	hist_dec = EmpiricalHistogram(dh_georef, :CU)
	
	plot(hist_dec, label=false, xlabel="Cu Declusterizado (%)",
	     color="darkgoldenrod1", alpha=0.55)
	
	vline!([sum_cu[:,:X̅]], label="X̅ Original",
		   color="red", ls=:dashdot, linewidth=1.5)
	
	vline!([sum_dec[:,:X̅]], label="X̅ Declusterizada",
		   color="red", ls=:solid, linewidth=1.5)
	
	vline!([sum_cu[:,:P50]], label="P50 Original",
		   color="green", ls=:dashdot, linewidth=1.5)
	
	vline!([sum_dec[:,:P50]], label="P50 Declusterizada",
		   color="green", ls=:solid, linewidth=1.5)
end

# ╔═╡ e7e21560-6991-11eb-1c07-99dd7413b3a7
md"""
- Uma vez que as amostras de Cu encontram-se agrupadas preferencialmente, foram calculadas estatísticas declusterizadas para essa variável.

- A média declusterizada representa **$(round(Int,((sum_dec[:,:X̅] / sum_cu[:,:X̅]) * 100)[1]))%** da média original. Ou seja, há uma diferença de **$(round((sum_cu[:,:X̅] - sum_dec[:,:X̅])[1], digits=2))%** de Cu entre a média original e a média declusterizada.

- Houve uma redução de **$(round((100.00 - ((sum_dec[:,:S] / sum_cu[:,:S]) *100)[1]),digits=2))%** do desvio padrão. Isso é curioso, já que, quando se aplica alguma técnica de declusterização, a tendência é haver um aumento na dispersão.
"""

# ╔═╡ 6e80e0b0-6942-11eb-3dac-1be7a41ff31d
md"""
#### Relação Média por Janela x Variabilidade por Janela
"""

# ╔═╡ 10dad9f0-698f-11eb-170a-e56e35e77dca
md"""
- O diagrama de dispersão abaixo (à esquerda) apresenta a relação entre médias e desvios padrões calculados a partir de janelas móveis.

- As janelas móveis podem ser definidas por meio do método `BlockPartitioner()` disponível no pacote **GeoStats.jl**. Os três _sliders_ abaixo controlam as três dimensões das janelas móveis.

- O cálculo de estatísticas de janelas móveis é frequentemente utilizado para investigar eventuais anomalias de tendência central e de dispersão. Nesse sentido, o depósito é subdividido (particionado) em diversas vizinhanças locais equidimensionais (janelas), de modo que as estatísticas (e.g. média e desvio padrão) locais são calculadas para cada janela.

- É importante que as janelas abranjam um número significativo de amostras para que as estatísticas calculadas sejam mais confiáveis.

- Assim, caso partições de dimensões pequenas sejam definidas, cada uma dessas unidades conterá um número pequeno de amostras e as estatísticas calculadas não serão confiáveis.

- Por outro lado, caso janelas de dimensões muito grandes sejam escolhidas, cada janela apresentará um número muito grande de amostras e as estatísticas calculadas não identificarão eventuais anomalias locais no depósito.

- Nesse sentido, o gráfico de barras (à direita) representa o número de amostras que cada uma das janelas contém.
"""

# ╔═╡ 43c02040-68eb-11eb-383d-e710b0a50fcf
md"""
Tam. da Janela em X: $(@bind Γ₁ Slider(100:50:400, default=400, show_value=true)) m

Tam. da Janela em Y: $(@bind Γ₂ Slider(100:50:400, default=400, show_value=true)) m

Tam. da Janela em Z: $(@bind Γ₃ Slider(25:25:75, default=50, show_value=true)) m
"""

# ╔═╡ 8fe3b4d0-68bb-11eb-1ae9-7beb74163940
begin
	Ω = partition(dh_georef, BlockPartition(Γ₁,Γ₂,Γ₃))
	
	medias_locais = []
	DP_locais = []
	num_elem = []
	
	for i in 1:length(Ω)
		append!(medias_locais, mean(Ω[i][:CU]))
		append!(DP_locais, std(Ω[i][:CU]))
		append!(num_elem, length(Ω[i][:CU]))
	end
	
	P₁ = scatter(medias_locais, DP_locais,
		    xlabel="X̅ por Janela", ylabel="S por Janela",
		    markersize=5, color="red", legend=false,
			marker=:diamond)
	
	P₂ = bar(1:length(num_elem), num_elem,
			 xlabel="Janelas", ylabel="N° Amostras",
			 legend=false, minorticks=true, color="gray90",
			 alpha=0.75)
	
	plot(P₁, P₂)

end		

# ╔═╡ 43b99380-698e-11eb-1289-b5907ecc753e
md"""
- Independentemente das dimensões definidas para as janelas, é possível confirmar que há uma clara relação de proporcionalidade entre as médias por janela e as dispersões por janela.

- O gráfico de dispersão enfatiza a presença de uma nítida relação monotônica positiva (talvez linear) entre médias e desvios padrões por janela.

- Essa relação entre ambas as estatísticas locais é geralmente denominada **Efeito Proporcional** e é muito comum em variáveis que apresentam distribuições assimétricas positivas (e.g. Lognormal, Exponencial).
"""

# ╔═╡ 47768810-6d4a-11eb-2a19-9d348e6117ae
md"""
#### Variogramas Omnidirecionais por Litologia
"""

# ╔═╡ 7580b9b0-6d4a-11eb-0b5e-9981665d3e41
md"""
###### Georreferenciamento dos dados por litologia
"""

# ╔═╡ 8ec82160-6d4a-11eb-004e-1b0519e69a41
begin
	GnP_georef = georef(GnP[:, [:X,:Y,:Z,:CU]], (:X,:Y,:Z))
	MzP_georef = georef(MzP[:,[:X,:Y,:Z,:CU]], (:X,:Y,:Z))
	TnP_georef = georef(TnP[:,[:X,:Y,:Z,:CU]], (:X,:Y,:Z))
end;

# ╔═╡ 2bf23340-6d4b-11eb-0801-abda77ea2c34
md"""
###### Cálculo dos variogramas omnidirecionais
"""

# ╔═╡ 6dc940a0-6d4c-11eb-366a-e7d1400bb0dd
md"""
###### Variogramas omnidirecionais
"""

# ╔═╡ 182879de-6d4c-11eb-19aa-f13d3b658689
md"""

№ lags: $(@bind nlags_omni Slider(5:1:20, default=10, show_value=true))

Lag máximo: $(@bind maxlags_omni Slider(300:25:500, default=350, show_value=true)) m

"""

# ╔═╡ d21ee65e-6d4a-11eb-11f2-370349470005
begin
	Random.seed!(1234)
	
	γ_GnP = EmpiricalVariogram(GnP_georef, :CU, maxlag=maxlags_omni, nlags=nlags_omni)
	γ_MzP = EmpiricalVariogram(MzP_georef, :CU, maxlag=maxlags_omni, nlags=nlags_omni)
	γ_TnP = EmpiricalVariogram(TnP_georef, :CU, maxlag=maxlags_omni, nlags=nlags_omni)
end;

# ╔═╡ 2a87f4e0-6d4b-11eb-1e9a-ada1e626fa68
begin
	plot(γ_GnP, xlims=(0.0, maxlags_omni), ylims=(0.0, 0.4),
		 marker=5, label="GnP")
	
	plot!(γ_MzP, xlims=(0.0, maxlags_omni), ylims=(0.0, 0.4),
		 marker=5, label="MzP")
	
	plot!(γ_TnP, xlims=(0.0, maxlags_omni), ylims=(0.0, 0.4),
		 marker=5, label="TnP")
	
	hline!([var(dh.CU)], color="gray", ls=:dash,
		   label=false, legend=:topleft)
end

# ╔═╡ b844ce00-694c-11eb-1300-ad41289f63a1
md"""
### Resumo

- Rossi & Deutsch (2013) afirmam que substâncias cujo CV < 50% apresentam baixa variabilidade, ou seja, são "bem comportadas". Como CV(Cu) ~ 50%, pode-se dizer que a **variável de interesse é pouco errática** e, nesse sentido, **não há necessidade de capeá-la** (o conceito de capeamento será discutido a frente).

- A variável **Cu** apresenta uma distribuição **assimétrica positiva e** é **leptocúrtica**.

- Existem **três litotipos** distintos no conjunto de dados (TnP, MzP e GnP) **distribuídos de forma balanceada**.

- A variável suporte amostral (`LENGTH`) apresenta uma distribuição assimétrica negativa, de modo que sua mediana é igual ao máximo suporte e o seu mínimo é igual à metade da mediana do suporte. Isso é um forte indício que os **furos já foram regularizados para um suporte amostral de 5 m**, por meio do algoritmo de Compositagem por Comprimento Fixo (os tipos de compositagem serão discutidos mais a frente).

- A **orientação majoritária dos furos** de sondagem é de aproximadamente **150°/55°**.

- O litotipo **Monzonito Pórfiro (MzP)** apresenta **maiores média e dispersão de Cu** do que as demais litologias. As **distribuições de Cu** para as litologias **Monzonito Pórfiro (MzP) e Granodiorito Pórfiro (GnP)** são muito **similares entre si**. Já a distribuição de Cu para o litotipo **Tonalito Pórfiro (TnP)** apresenta **média e variabilidade inferiores** quando comparada às demais litologias.

- Nota-se um **agrupamento preferencial sutil em porções mais "ricas" do depósito**. Portanto, a partir do cálculo de estatísticas declusterizadas para mitigar o viés cognitivo da amostragem, houve uma **redução de ~9% da média amostral e de ~5% do desvio padrão amostral**.

- É possível perceber uma **relação monotônica crescente entre média e dispersão por janelas (Efeito Proporcional)**, o que era de se esperar, já que a variável de interesse apresenta uma distribuição assimétrica positiva.

- Os **variogramas** experimentais **omnidirecionais** calculados **por litologia indicam que há uma variação nos alcances e patamares** para cada litotipo, o que reforça a ideia de que a **estimativa deve ser conduzida em domínios distintos** (por litologia).

- Entretanto, **para efeitos de simplificação**, iremos conduzir a estimativa, considerando que todo o **banco de dados será tratado como um único domínio estacionário**.


"""

# ╔═╡ 92738660-698a-11eb-1f33-894a5df007a8
html"""<hr><hr>"""

# ╔═╡ 9d85ff60-698a-11eb-0487-a1d94d457220
html"""
	<div id="preparacao_de_amostras">

		<h2>5. Preparação de Amostras</h2>

	</div>
"""

# ╔═╡ aac3a530-6d4d-11eb-085d-1bab15c19010
md"""
### Compositagem (*Compositing*)
"""

# ╔═╡ 92908910-6e10-11eb-381a-51d5a94c7da7
md"""
#### Introdução

Dados brutos de sondagem normalmente são obtidos em suportes amostrais variados. Nesse sentido, caso não houver um tratamento prévio desses dados, amostras de diferentes suportes amostrais terão mesmo peso na estimativa (Sinclair & Blackwell, 2006).

Portanto, um procedimento denominado **compositagem** deve ser conduzido, visando os seguintes objetivos:

- Regularizar o suporte amostral, de modo a reduzir a variância do comprimento das amostras (compositagem ao longo do furo).

- Aumentar o suporte amostral (suporte x variância = k).

- Adequar o comprimento das amostras à escala de trabalho (compositagem por bancadas).

Existem basicamente três tipos de compositagem, de forma que neste treinamento abordaremos apenas o  primeiro:

- **Compositagem ao longo do furo**.

- **Compositagem por bancadas**.

- **Compositagem por critério minério/estéril**.

"""

# ╔═╡ 1c473190-6e57-11eb-0688-ed685c6d4080
md"""
#### Teores Compostos

Quando a compositagem é realizada, os teores originais são recalculados, a partir de uma média dos teores amostrais ponderada pelo comprimento amostral. Os teores resultantes são denominados **teores compostos (Tc)**.

```math
Tc = \frac{\sum_{i=1}^{n} tᵢ.eᵢ}{\sum_{i=1}^{n} eᵢ}
```

- tᵢ = teor original da i-ésima amostra.
- eᵢ = comprimento original da i-ésima amostra.

A Figura 5 ilustra um esquema simplificado de compositagem de um furo vertical por bancadas de 10 metros:

"""

# ╔═╡ 26c5c7a0-6e5a-11eb-2e60-cfc5dcac3aaa
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_05">
</p>

<p align="center">
	<b>Figura 5</b>: Exemplo de compositagem por bancadas de 10 m de um furo vertical (Yamamoto, 2001). .
</p>
"""

# ╔═╡ 53f60710-6e25-11eb-13c8-dba3ac9d77aa
html"""<hr>"""

# ╔═╡ a035e1f0-6e10-11eb-2583-3f69db55f2df
md"""
#### Considerações Importantes

- A compositagem evita que amostras de diferentes suportes tenham o mesmo peso na estimativa.

- A compositagem é imprescindível para realizar estimativa por krigagem (Abzalov, 2016).

- É importante que a compositagem seja realizada de modo a respeitar os domínios de estimativa/estacionários.

- A variância pode ser entendida como incerteza da estimativa e, portanto, deve ser minimizada.

- A compositagem não deve aumentar o número de amostras. Em outras palavras, esse procedimento não deve "criar" novas amostras, mas sim combiná-las de modo a produzir composites de suporte aproximadamente uniforme (Abzalov, 2016; Sinclair & Blackwell, 2006).
"""

# ╔═╡ 4b581080-6e25-11eb-2af9-1364ad8550de
html"""<hr>"""

# ╔═╡ 03614a70-6e0d-11eb-168c-e534b1963bdc
md"""
#### Relação Suporte Amostral x Variância

O **suporte amostral** está associado ao tamanho, diâmetro, peso e orientação de cada unidade amostral presente nos furos de sondagem. De forma simplificada, podemos pensar em suporte amostral como o tamanho (`LENGTH`) de cada unidade amostral presente na base de dados.

Nesse sentido, surge um importante conceito geoestatístico denominado **relação suporte x variância**. Pode-se pensar que o produto entre o suporte amostral e a variância associada ao suporte é igual a uma constante. Alternativamente, pode-se dizer que há uma relação inversamente proporcional entre suporte e variância (Figura 6):

- Quanto **maior** o **suporte** amostral, **menor** a **variância** associada.

- Quanto **menor** o **suporte** amostral, **maior** a **variância** associada.
"""

# ╔═╡ 3f360c00-6e14-11eb-0b61-f19f312af7cc
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_06">
</p>

<p align="center">
	<b>Figura 6</b>: Relação suporte x variância para distintos tamanhos de composite (Sinclair & Blackwell, 2006).
</p>
"""

# ╔═╡ e697a030-6e14-11eb-0740-bd7efaef212a
md"""
###### Exemplo

Vamos imaginar dois cenários distintos:

- No primeiro cenário, imagine que temos uma única pilha com milhares de _chips_ de minério de ferro. Nesse contexto, o suporte amostral é representado pelo tamanho de cada _chip_ de minério (Figura 7A).

- No segundo cenário, imagine agora que temos 5 pilhas de minério de ferro. Nesse cenário, o suporte amostral é definido como o tamanho de cada pilha de minério (Figura 7B).

Nesse sentido, em qual dos cenários espera-se a maior variância associada aos respectivos suportes amostrais?
"""

# ╔═╡ d39e0810-6e15-11eb-26fa-cb8dc416efdf
html"""
<p align="center">

	<img src="Caminho/da/FiguraXX" alt="Figura_07" width="400px">
</p>

<p align="center">
	<b>Figura 7</b>: Exemplo de relação suporte x variância. <b>(A)</b> Primeiro cenário. <b>(B)</b> Segundo cenário.
</p>
"""

# ╔═╡ 41366022-6e25-11eb-2f5f-e326ca201f8c
html""" <hr> """

# ╔═╡ 608b68d0-6e20-11eb-07f2-a9bc08859292
md"""
#### Compositagem ao Longo do Furo

Conforme dito anteriormente, a compositagem ao longo do furo tem como principais objetivos regularizar e aumentar o suporte amostral, de modo a reduzir a variância do comprimento das amostras.

Existem dois algoritmos principais de compositagem ao longo do furo (Abzalov, 2016):

- **Algoritmo do Comprimento Fixo**.

- **Algoritmo do Comprimento Ótimo**.

A compositagem ao longo do furo pode ser executada a partir da função `composite()`, disponível no pacote `DrillHoles.jl`

"""

# ╔═╡ 036adad0-6e22-11eb-08eb-83e628823098
md"""
##### Algoritmo do Comprimento Fixo

Este algoritmo visa a criação de composites de tamanhos (`interval`) idênticos entre si. Entretanto, pode haver descarte de bordas de unidades amostrais, cujo tamanho for inferior ao valor de `mincomp` (Figura 8).

- Baixa flexibilidade.

- Pode haver perda de amostras.

- Pode gerar uma elevada variância.

- Distribuição das composites tipicamente assimétrica negativa.

- *Min(composite) = ½ P50(composite)*.

- *Max(composite) = P50(composite)*.

- Parâmetro `mode = :equalcomp` na função `composite()`.

OBS.: Conforme discutido na AED, os furos deste banco de dados já se encontram compositados pelo algoritmo do Comprimento Fixo.
"""

# ╔═╡ 924c4eee-6e22-11eb-1906-3d5589077bc7
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_08">
</p>

<p align="center">
	<b>Figura 8</b>: Compositagem ao longo do furo pelo Algoritmo do Comprimento Fixo (adaptado de Abzalov, 2016).
</p>
"""

# ╔═╡ 492eb2be-6e23-11eb-09af-7bf51a7ef5ec
md"""
##### Algoritmo do Comprimento Ótimo

Este algoritmo visa gerar composites, de modo a incluir todas as bordas de unidades amostrais em algum composite. Portanto, embora o comprimento amostral não seja rigidamente fixo, não há descarte de bordas de amostras (Figura 9).

- Alta flexibilidade.

- Não há perda de amostras.

- Normalmente, há uma maior redução da variância de suporte, quando comparado com o Algoritmo do Comprimento Fixo.

- Distribuição das composites tipicamente simétrica.

- Max (composite) = 1.5 x `interval`.

- Parâmetro `mode = :nodiscard` na função `composite()`.
"""

# ╔═╡ 27d99bb0-6e25-11eb-2ada-efd7d4d70e75
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_09">
</p>

<p align="center">
	<b>Figura 9</b>: Compositagem ao longo do furo pelo Algoritmo do Comprimento Ótimo (adaptado de Abzalov, 2016).
</p>
"""

# ╔═╡ b5f37a0e-6e25-11eb-1489-11ab0855526c
md"""
##### Comparação entre os Algoritmos

A Figura 10 ilustra uma comparação estatística entre os resultados de compositagem ao longo do furo obtidos para os dois algoritmos:
"""

# ╔═╡ 3399c460-6e26-11eb-01f7-dd20d15d4225
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_10">
</p>

<p align="center">
	<b>Figura 10</b>: Comparação entre algoritmos de compositagem ao longo do furo (adaptado de Abzalov, 2016).
</p>
"""

# ╔═╡ 654d9d10-6e26-11eb-3cdd-e974e3decbc5
html"""<hr>"""

# ╔═╡ 6c79db30-6e26-11eb-00fd-49afdf7a366a
md"""
#### Validação da Compositagem

De acordo com Abzalov (2016), alguns pontos devem ser validados, com o intuito de se avaliar a performance da compositagem:

- O tamanho definido para as composites (`interval`) deve ser maior do que a média dos comprimentos amostrais originais (idealmente não se deve criar amostras).

- O tamanho de composite escolhido (`interval`) deve ser aproximadamente metade do tamanho do bloco utilizado na krigagem.

- Diferenças superiores a 5% entre as médias dos teores originais (brutos) e os teores compostos são indesejadas.

- Diferenças superiores a 5% entre a soma dos comprimentos das amostras originais e a soma dos comprimentos das amostras compositadas são indesejadas.
"""

# ╔═╡ 60a38f70-6e46-11eb-20c4-0b0594eb96a0
html"""<hr><hr>"""

# ╔═╡ b42030d0-6d4d-11eb-36ff-33e5dddea922
md"""
### Capeamento (*Capping/Top-Cut*)
"""

# ╔═╡ 8125afd0-6e28-11eb-0e6a-a75e65e0bf92
md"""
#### Introdução

Na mineração, frequentemente lidamos com a estimativa de metais que apresentam distribuições fortemente assimétricas positivas (principalmente elementos menores, como Au, Cu, Pt, Ag, U).

Nesse sentido, alguns poucos teores mostram-se muito discrepantes em relação ao restante da distribuição e, por isso, são frequentemente chamados de **outliers**.

O não tratamento dos _outliers_ pode causar uma série de problemas, dentre eles:

- Superestimativa dos recursos (criação de "ilhas de high grades" que não refletem a realidade do depósito).

- Teores estimados negativos (pesos negativos atribuidos a *outliers* podem ocasionar teores estimados negativos).

Portanto, o processo denominado **capeamento** surge justamente para mitigar o efeito de valores anômalos na estimativa de recursos. Esse procedimento pode ser dividido em duas etapas:

- **Detecção de Outliers**.

- **Tratamento de Outliers**.

"""

# ╔═╡ 6daa5e60-6e46-11eb-1c8e-afd6295a2c54
html"""<hr>"""

# ╔═╡ 3688b4b0-6e2b-11eb-1dce-2119db7856b7
md"""
#### Detecção de Outliers

Nesta etapa, definimos um critério para delimitar a partir de qual limite superior iremos considerar os valores de teor como *outliers*. Algumas abordagens referidas na literatura são (Abzalov, 2016):

- Cenário 1: *outliers* > P75 + 1.5(IQR)

- Cenário 2: *outliers* > X̅ + 6.S

- Cenário 3: *outliers* > X̅ + 2.S

- Cenário 4: *outliers* > 4.X̅

- Cenário 5: *outliers* > P95

- Cenário 6: *outliers* > último ponto de inflexão da curva de frequência acumulada.
"""

# ╔═╡ 38876380-6e2e-11eb-09fc-bd56e6f1aee8
begin
	cen_1 = (sum_cu.P75 + 1.5*(sum_cu.IQR))[1]
	cen_2 = (sum_cu.X̅ + (6 * sum_cu.S))[1]
	cen_3 = (sum_cu.X̅ + (2 * sum_cu.S))[1]
	cen_4 = (4 * sum_cu.X̅)[1]
	cen_5 = quantile(dh.CU, [0.95])[1]
end;

# ╔═╡ 49ee4650-6e30-11eb-0f73-cb0ead7f16c6
md"""
Limiar Superior: $(@bind cen_6 Slider(0.20:0.01:3.43, default=3.43, show_value=true)) %
"""

# ╔═╡ e3eadb70-6e2f-11eb-1c38-0bfc615d6559
begin
	plot(ecdf(dh.CU), color=:red, label=false,
	 xlabel="Cu (%)", ylabel="Frequência Acumulada Relativa")
	
	vline!([cen_6], color=:gray, ls=:dash, label=false)
end

# ╔═╡ 88a828a0-6e46-11eb-39a0-b75f488c730a
html"""<hr>"""

# ╔═╡ 6ee37970-6e2c-11eb-001e-bb716b10fb40
md"""
#### Tratamento de Outliers

Após a definição do limiar superior de *outliers*, devemos definir o que será feito com esses valores extremos. Existem duas abordagens básicas:

- Truncamento (exclusão dos *outliers* do banco de dados).

- Winsorização (*outliers* são igualados ao valor do limiar superior estabelecido).

Como na grande maioria das vezes os *outliers* são valores anômalos reais (ou seja, não são oriundos de erros), optaremos pelo tratamento via winsorização.
"""

# ╔═╡ 366c9270-6e31-11eb-20fe-9b45627cfcaa
begin
	win_cen_1 = replace(v -> v > cen_1 ? cen_1 : v, dh.CU)
	win_cen_2 = replace(v -> v > cen_2 ? cen_2 : v, dh.CU)
	win_cen_3 = replace(v -> v > cen_3 ? cen_3 : v, dh.CU)
	win_cen_4 = replace(v -> v > cen_4 ? cen_4 : v, dh.CU)
	win_cen_5 = replace(v -> v > cen_5 ? cen_5 : v, dh.CU)
	win_cen_6 = replace(v -> v > cen_6 ? cen_6 : v, dh.CU)
end;

# ╔═╡ 91e03c50-6e46-11eb-047b-59a78ffec642
html"""<hr>"""

# ╔═╡ ebc5d780-6e2c-11eb-3ceb-7d1b08e93828
md"""
#### Validação do Capeamento

Após as etapas anteriores, devemos validar os resultados do capeamento obtidos. Nesse sentido, devemos verificar se há uma variação muito grande entre a média amostral original e a média amostral capeada.

Sugere-se que todas as técnicas de capeamento sejam testadas como cenários distintos e comparadas entre si. Se possível, deve-se realizar uma validação baseada na reconciliação entre modelos estimados (com diferentes cenários de capeamento), os dados de produção e o modelo de *grade control*.

"""

# ╔═╡ 3db6dee2-6e3c-11eb-275a-cbe86810c188
begin
	media_orig = sum_cu.X̅[1]
	media_cen_1 = round(mean(win_cen_1), digits=2)
	media_cen_2 = round(mean(win_cen_2), digits=2)
	media_cen_3 = round(mean(win_cen_3), digits=2)
	media_cen_4 = round(mean(win_cen_4), digits=2)
	media_cen_5 = round(mean(win_cen_5), digits=2)
	media_cen_6 = round(mean(win_cen_6), digits=2)
	
	dif_perc_cen1 = round((100.0 - ((media_orig / media_cen_1) * 100.0)), digits=2)
	dif_perc_cen2 = round((100.0 - ((media_orig / media_cen_2) * 100.0)), digits=2)
	dif_perc_cen3 = round((100.0 - ((media_orig / media_cen_3) * 100.0)), digits=2)
	dif_perc_cen4 = round((100.0 - ((media_orig / media_cen_4) * 100.0)), digits=2)
	dif_perc_cen5 = round((100.0 - ((media_orig / media_cen_5) * 100.0)), digits=2)
	dif_perc_cen6 = round((100.0 - ((media_orig / media_cen_6) * 100.0)), digits=2)
	
end;

# ╔═╡ ea17f0b0-6e3d-11eb-24a9-d7429c2f7a1c
md"""

|    Cenário    | Média Original | Média Capeada |   Diferença %   |
|:-------------:|:--------------:|:-------------:|:---------------:|
| P75 + 1.5(IQR)|   $media_orig  |  $media_cen_1 |$(dif_perc_cen1)%|
|    X̅ + 6.S    |   $media_orig  |  $media_cen_2 |$(dif_perc_cen2)%|
|    X̅ + 2.S    |   $media_orig  |  $media_cen_3 |$(dif_perc_cen3)%|
|      4.X̅      |   $media_orig  |  $media_cen_4 |$(dif_perc_cen4)%|
|      P95      |   $media_orig  |  $media_cen_5 |$(dif_perc_cen5)%|
|Ponto Inflexão |   $media_orig  |  $media_cen_6 |$(dif_perc_cen6)%|

"""

# ╔═╡ 74881010-69a0-11eb-0f7b-174e062822d5
html"""<hr><hr>"""

# ╔═╡ 650cbc40-6a30-11eb-005d-210b5b4b7320
html"""
	<div id="vg_exp_model_vg">

		<h2>6. Variografia Experimental & Modelagem Variográfica</h2>

	</div>
"""

# ╔═╡ cb7ae490-6eca-11eb-10b3-ebda08aee935
md"""
#### Função Variograma/Semivariograma

- A **função variograma** é uma função matemática que mapeia o comportamento espacial de uma variável regionalizada. No nosso caso, essa variável é o Cu.

```math

γ(h) = \frac{1}{2n} \sum_{i=1}^{n} [Z(xᵢ) - Z(xᵢ + h)]^2

```

- O variograma, quando existe, é único e válido para todo o domínio de estimativa.

- Embora realizemos múltiplas representações gráficas de variogramas experimentais e modelos teóricos de variograma, ainda sim a função variograma é única para cada domínio de estimativa!

- O **variograma experimental** é sensível à direção, mas não ao sentido. Isso ocorre, uma vez que assume-se um contexto de estacionariedade de 2ª ordem.
    - Exemplo: o variograma experimental no sentido 000°/45° é igual ao variograma experimental no sentido 180°/45°. Por essa razão, calculamos variogramas experimentais variando apenas 

- Já o **modelo teórico do variograma** é isotrópico.
"""

# ╔═╡ ab46b930-70c1-11eb-3e81-bf4b5fda7de6
md"""---"""

# ╔═╡ 2684f1d0-6ecd-11eb-3254-7d4956805de9
md"""
#### Propriedades do Variograma

As propriedades do variograma são apresentadas na Figura 11.
"""

# ╔═╡ d3a34e42-6ed0-11eb-3a63-9b1a2cd29fde
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_11">
</p>

<p align="center">
	<b>Figura 11</b>: Propriedades do variograma.
</p>
"""

# ╔═╡ d4845f70-6ed0-11eb-17bf-3f684368f247
md"""
- **Efeito Pepita (C₀)**: é a descontinuidade **próxima à origem** do variograma. Em outras palavras, é o valor do variograma (γ) quando a distância (h) **tende a zero**:
    - γ(h → 0) = C₀
    - OBS.: γ(h = 0) = 0

- **Variância Espacial (C)**: medida de dissimilaridade entre dois pontos no espaço, dada uma distância (h) em uma determinada direção. Do ponto de vista matemático, é a diferença quadrática entre um par de unidades amostrais separadas por uma distância (h).

- **Patamar (C₀ + C)**: é o máximo valor de variância espacial que os dados podem apresentar.

- **Amplitude/Alcance (a)**: é a distância máxima até onde se consegue estabelecer alguma dependência espacial entre pares de unidades amostrais. Em outras palavras, o alcance marca a saída do campo estruturado do variograma e entrada do campo aleatório (não estruturado).

- **Campo Estruturado (Geométrico)**: região com distâncias menores do que o alcance do variograma, onde ainda há dependência/estrutura espacial entre pares de pontos. Seu valor é de aproximadamente metade da extensão amostral em uma determinada direção.

- **Campo Não Estruturado (Aleatório)**: região cujas distâncias são maiores do que o alcance do variograma, ou seja, onde não há mais dependência espacial entre pares de pontos.
    - Nesse campo, a variância espacial é máxima, constante e, idealmente, igual à variância à priori dos dados (quando não há um *trend* espacial).

OBS.: os campos estruturado e aleatório não são propriedadades do variograma. Na realidade, eles são consequências da amplitude do variograma que, por sua vez, é uma propriedade verdadeira.
"""

# ╔═╡ b536f950-70c1-11eb-1f17-9939a8b0c241
md"""---"""

# ╔═╡ fe797dfe-6ed0-11eb-0a1c-f12aed1aedc5
md"""
#### Variograma Experimental x Modelo Teórico do Variograma

- **Variograma Experimental**:
    - Varia de acordo com a direção em que é calculado.
    - É uma **função discreta**.
    - Seu cálculo é realizado com base na equação da função variograma apresentada anteriormente.

- **Modelo Teórico do Variograma**:
    - É isotrópico.
    - É uma **função contínua**.
    - É representado por algum modelo determinístico conhecido (Gaussiano, Esférico, Exponencial, etc...)

- A figura abaixo ilustra um variograma experimental (Figura 12A) e seu respectivo modelo teórico ajustado (Figura 12B):
"""

# ╔═╡ 15e6c720-6ed4-11eb-01a5-e5670049de1a
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_12">
</p>

<p align="center">
	<b>Figura 12</b>: Exemplos de <b>(A)</b> variograma experimental e <b>(B)</b> seu respectivo modelo teórico ajustado.
</p>
"""

# ╔═╡ b883da60-70c1-11eb-29f4-395359a6cb01
md"""---"""

# ╔═╡ a60ab840-6ed2-11eb-09eb-39c6e752dce8
md"""
#### Cálculo do Variograma Experimental

Para o cálculo dos variogramas experimentais, precisamos definir alguns parâmetros, como: tamanho do passo (lag), número de passos (`nlags`), tamanho máximo de passo (`maxlag`), tolerância do passo (lagtol) e largura da banda (`dtol`).

Utilizaremos a função `DirectionalVariogram()`, disponível no pacote **GeoStats.jl**.

Nesse sentido, devemos definir quatro parâmetros para o cálculo dos variogramas experimentais:
- **Direção**: a direção em que o variograma experimental será calculado.
    - No pacote **GeoStats.jl**, a direção deve ser informada como uma tupla de coordenadas cartesianas (xᵢ, yᵢ, zᵢ). Nesse sentido, criei a função `polar2cart()` para informarmos a direção de uma forma mais intuitiva, ou seja, em coordenadas polares (azi/dip).

- **Tamanho máximo de passo (`maxlag`)**: até qual tamanho de passo o variograma experimental deve ser calculado. É desejável que esse valor seja um pouco maior que o campo estruturado do variograma. Podemos utilizar, para os variogramas direcionais, o valor de **350 m** para o **tamanho máximo de passo**, ou seja, o valor aproximado do campo estruturado do variograma (metade da extensão amostral média).

- **Número de passos (`nlags`)**: número de passos que o variograma experimental apresentará. Para os variogramas direcionais, **10** é um valor razoável para o número de **passos**. Esse palpite inicial é dado pela razão entre o campo geométrico do variograma (*L/2*) e o tamanho do passo (*lag*):

```math
nlags = \frac{(L/2)}{lag}
```

- **Largura da banda (`dtol`)**: como no pacote **GeoStats.jl** não é possível informar diretamente a tolerância de azimute e de mergulho, utilizaremos a largura da banda para estimarmos a tolerância angular. Para os variogramas direcionais, um valor razoável é de **70 m** para a **largura da banda**.
    - Por padrão do pacote *GeoStats.jl*, a largura da banda não permite a exclusão ou sobreposição de tolerâncias angulares.

OBS.: O tamanho do passo (*lag*) é definido pela seguinte razão:

```math
lag = \frac{maxlag}{nlags}
```

OBS.: a tolerância de passo (*lagtol*) padrão do pacote **GeoStats.jl** é definida como metade do tamanho de passo:

```math
lagtol = \frac{1}{2}lag
```
A Figura 13 ilustra os parâmetros que devem ser definidos para o cálculo do variograma experimental:

"""

# ╔═╡ 64a6fa90-6edb-11eb-3e7c-83836ffe0ad6
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_13">
</p>

<p align="center">
	<b>Figura 13</b>: Parâmetros para o cálculo do variograma experimental (Deutsch, 2015).
</p>
"""

# ╔═╡ be39f340-70c1-11eb-32e8-1375297fb833
md"""---"""

# ╔═╡ 6d6ab7b0-6ed2-11eb-0a14-116ffc586617
md"""
#### Modelos Teóricos de Variograma

Os **modelos teóricos de variograma**, por serem isotrópicos, não reconhecem anisotropia (não variam com a direção).

Como os variogramas experimentais são funções discretas, é necessário ajustar um modelo matemático contínuo a essas funções, de modo que saberemos o valor do variograma (γ) para qualquer distância (h).

É importante ressaltar que apenas **funções contínuas e monotônicas crescentes** podem ser utilizadas como ajustes teóricos de variograma.
- Se ajustássemos um variograma experimental com um modelo teórico não monotônico, correríamos o risco de termos valores negativos de covariância na matriz de krigagem.

Nesse sentido, existem três principais modelos teóricos de variograma amplamente utilizados:

"""

# ╔═╡ 3b3a7ce0-6eef-11eb-1c15-dd5f7a07424a
md"""
##### Modelo Gaussiano

- Apresenta **comportamento próximo à origem parabólico**.

- Nesse sentido, esse tipo de modelo teórico é normalmente utilizado para ajustar variogramas experimentais de fenômenos de **baixa heterogeneidade**, ou seja, variáveis que apresentam maior continuidade espacial.

- Pode ou não apresentar efeito pepita.

- Sua equação é descrita como:

``` math
γ(h) = C₀ + C \left[ 1 - exp \left[- \left(\frac{h}{a} \right)^2 \right]  \right] 
```
"""

# ╔═╡ 8231568e-6ef0-11eb-32ab-450855d94b94
md"""
Efeito Pepita: $(@bind gauss_c₀ Slider(0.00:0.05:0.5, default=0.0, show_value=true))

Alcance: $(@bind gauss_a Slider(1.0:1.0:15.0, default=5.0, show_value=true)) m

Patamar: $(@bind gauss_s Slider(0.5:0.05:1.0, default=0.75, show_value=true))

"""

# ╔═╡ b212fcc0-6eef-11eb-23af-6d8dcaef4fcc
begin
	γ_gauss = GaussianVariogram(nugget=Float64(gauss_c₀),
								range=Float64(gauss_a),
								sill=Float64(gauss_s))
	
	plot(γ_gauss, 0, 20, ylims=(0.0, 1.2), xlims=(0,20),
		 label="Modelo Gaussiano", color=:red, lw=2)
	
	vline!([gauss_a], color=:green, ls=:dash, label="Alcance")
	
	hline!([gauss_s], color=:gray, ls=:dashdotdot, label="Patamar")
end

# ╔═╡ 742234d0-6eef-11eb-39cb-49b7ec370a90
md"""
##### Modelo Esférico

- Apresenta **comportamento próximo à origem linear**.

- Nesse sentido, esse tipo de modelo teórico é normalmente utilizado para ajustar variogramas experimentais de fenômenos de **intermediária heterogeneidade**, ou seja, variáveis que apresentam continuidade espacial moderada.

- Pode ou não apresentar efeito pepita.

- Sua equação é descrita como:

``` math
γ(h) = C₀ + C \left[\frac{3h}{2a} - \frac{1}{2}.\left(\frac{h}{a}\right)^3 \right], ∀ h < a)
```
``` math
γ(h) = C₀ + C, ∀ h ≥ a
```

"""

# ╔═╡ 8149cad0-6ef2-11eb-321f-f54f84c1c7c0
md"""
Efeito Pepita: $(@bind sph_c₀ Slider(0.00:0.05:0.5, default=0.0, show_value=true))

Alcance: $(@bind sph_a Slider(1.0:1.0:15.0, default=5.0, show_value=true)) m

Patamar: $(@bind sph_s Slider(0.5:0.05:1.0, default=0.75, show_value=true))

"""

# ╔═╡ 80418290-6ef2-11eb-157c-6d31f48c50b5
begin
	γ_sph = SphericalVariogram(nugget=Float64(sph_c₀),
								range=Float64(sph_a),
								sill=Float64(sph_s))
	
	plot(γ_sph, 0, 20, ylims=(0.0, 1.2), xlims=(0,20),
		 label="Modelo Esférico", color=:red, lw=2)
	
	vline!([sph_a], color=:green, ls=:dash, label="Alcance")
	
	hline!([sph_s], color=:gray, ls=:dashdotdot, label="Patamar")
end

# ╔═╡ 8715e410-6eef-11eb-1326-f360026efe4b
md"""
##### Modelo Exponencial

- Apresenta **comportamento próximo à origem linear**. Entretanto, a inclinação desse modelo nas proximidades da origem é maior do que a inclinação do Modelo Esférico.

- Nesse sentido, esse tipo de modelo teórico é normalmente utilizado para ajustar variogramas experimentais de fenômenos de **elevada heterogeneidade**, ou seja, variáveis que apresentam continuidade espacial limitada.

- Pode ou não apresentar efeito pepita.

- Sua equação é descrita como:

``` math
γ(h) = C₀ + C \left[1 - exp \left[-\left(\frac{h}{a} \right) \right] \right]
```

"""

# ╔═╡ d09a82a0-6ef2-11eb-2a25-d153d45e0761
md"""
Efeito Pepita: $(@bind exp_c₀ Slider(0.00:0.05:0.5, default=0.0, show_value=true))

Alcance: $(@bind exp_a Slider(1.0:1.0:15.0, default=5.0, show_value=true)) m

Patamar: $(@bind exp_s Slider(0.5:0.05:1.0, default=0.75, show_value=true))

"""

# ╔═╡ cfc97700-6ef2-11eb-0887-a323d911410e
begin
	γ_exp = ExponentialVariogram(nugget=Float64(exp_c₀),
								range=Float64(exp_a),
								sill=Float64(exp_s))
	
	plot(γ_exp, 0, 20, ylims=(0.0, 1.2), xlims=(0,20),
		 label="Modelo Exponencial", color=:red, lw=2)
	
	vline!([exp_a], color=:green, ls=:dash, label="Alcance")
	
	hline!([exp_s], color=:gray, ls=:dashdotdot, label="Patamar")
end

# ╔═╡ c82be110-70c1-11eb-2145-3df3e649304d
md"""---"""

# ╔═╡ ddc45070-6ed2-11eb-205e-57d941c5d670
md"""
#### Fluxograma Variografia 3D

A Figura 14 ilustra o fluxograma de como é realizada a variografia em um contexto tridimensional.
"""

# ╔═╡ 55af6e6e-6ef7-11eb-1bba-adc8d062797e
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_14">
</p>

<p align="center">
	<b>Figura 14</b>: Fluxograma da variografia 3D.
</p>
"""

# ╔═╡ d6e9fcf0-70c1-11eb-0df6-8f6cef676371
md"""---"""

# ╔═╡ 88a02590-6cd6-11eb-080b-437e5a93d25c
md"""
###### Função polar2cart

Função auxiliar criada para converter uma medida do tipo `(azi/dip)` para `(xᵢ, yᵢ, zᵢ)`, uma vez que a direção do variograma deve ser informada em coordenadas cartesianas.
"""

# ╔═╡ 2289b110-6a27-11eb-2ba0-0735998426e8
function polar2cart(azi, dip)
	azi_rad = deg2rad(azi)
	dip_rad = deg2rad(dip)
	x = sin(azi_rad) * cos(dip_rad)
	y = cos(azi_rad) * cos(dip_rad)
	z = (sin(dip_rad)) * -1
	return (x, y, z)
end

# ╔═╡ edafc2d0-70c1-11eb-0cb8-ef3150995f11
md"""---"""

# ╔═╡ 7606a440-6cd6-11eb-1adb-bd52f7a637da
md"""
#### Variograma Experimental - Down Hole
"""

# ╔═╡ d18ecd10-6cd6-11eb-235e-3b9a6bbe040d
md"""

№ lags: $(@bind nlags_dh Slider(10:1:25, default=20, show_value=true))

Largura da banda: $(@bind bw_dh Slider(10:5:50, default=45, show_value=true)) m
"""

# ╔═╡ 449534f0-6a27-11eb-0ca5-d1b0e4ce75c2
begin
	Random.seed!(1234)

	γ_dh = DirectionalVariogram(polar2cart(150,55),
		   						dh_georef, :CU,
								dtol=bw_dh, maxlag=150,
								nlags=nlags_dh)
end

# ╔═╡ a01194c0-6cd6-11eb-36cd-edde6d7b6076
begin
	plot(γ_dh, marker=5, ylims=(0, 0.3), color=:deepskyblue, title="150°/55°")
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
end

# ╔═╡ 3593cfde-6cd7-11eb-0102-2175cdf86cae
md"""
#### Modelo do Variograma - Down Hole
"""

# ╔═╡ b5dd4960-6cb9-11eb-2e03-530f378cb25a
md"""
Efeito Pepita: $(@bind c₀ Slider(0.00:0.005:0.06, default=0.045, show_value=true))

Variância Espacial 1ª Estrutura: $(@bind c₁ Slider(0.045:0.005:0.18, default=0.06, show_value=true))

Variância Espacial 2ª Estrutura: $(@bind c₂ Slider(0.045:0.005:0.18, default=0.075, show_value=true))

Alcance 1ª Estrutura: $(@bind a_dh1 Slider(10.0:2.0:80.0, default=70.0, show_value=true)) m

Alcance 2ª Estrutura: $(@bind a_dh2 Slider(10.0:2.0:140.0, default=86.0, show_value=true)) m

"""

# ╔═╡ 6c04582e-6a64-11eb-3fc5-572e3489a0b7
begin
	
	model_dh0 = NuggetEffect(nugget=c₀)
	
	model_dh1 = SphericalVariogram(sill=Float64(c₁),
								   range=Float64(a_dh1))
	
	model_dh2 = SphericalVariogram(sill=Float64(c₂),
								   range=Float64(a_dh2))
	
	model_dh = model_dh0 + model_dh1 + model_dh2
	
	plot(γ_dh, ylims=(0, 0.3), marker=5, color=:deepskyblue)
	
	plot!(model_dh, 0, 110, legend=:right,
		  title="150°/55°",
		  ylims=(0, 0.3), color=:red, lw=2)
	
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
	
	vline!([a_dh2], color="green", ls=:dash, legend=false)
	
end

# ╔═╡ f94a7ea2-70c1-11eb-009d-7184b6bb72da
md"""---"""

# ╔═╡ 0e4c40c0-6cb9-11eb-148a-e3004deca84d
md"""
### Variogramas Direcionais
"""

# ╔═╡ 250c3a40-6cb9-11eb-0a5f-23b3bddb6875
md"""
#### Variograma Experimental - Azimute
"""

# ╔═╡ c463b470-6cae-11eb-0a61-239e567d5207
md"""
Azimute: $(@bind azi Slider(0.0:22.5:67.5, default=67.5, show_value=true))°

№ lags: $(@bind nlags_azi Slider(5:1:12, default=10, show_value=true))

Largura de Banda: $(@bind bw_azi Slider(10:10:100, default=70, show_value=true)) m
"""

# ╔═╡ ccd392f0-6caa-11eb-2775-0bb711433969
begin
	Random.seed!(1234)
	
	γ_azi_1 = DirectionalVariogram(polar2cart(azi,0.0),
								   dh_georef, :CU,
								   dtol=bw_azi, maxlag=350,
								   nlags=nlags_azi)
	
	γ_azi_2 = DirectionalVariogram(polar2cart((azi+90.0),0.0),
								   dh_georef, :CU, dtol=bw_azi,
								   maxlag=350, nlags=nlags_azi)

end

# ╔═╡ 25fdce90-6cab-11eb-0bf1-6b67009a90fc
begin
	plot(γ_azi_1, marker=5, ylims=(0, 0.4), label="0$(azi)°", color=:red)
	
	plot!(γ_azi_2, marker=5, ylims=(0, 0.4), label="$(azi+90)°", color=:deepskyblue,
		  legend=:topright, title="Variogramas Direcionais Ortogonais")
	
	hline!([var(dh.CU)], color="gray", ls=:dash, label=false)
	
end

# ╔═╡ d0170e10-6cbe-11eb-25e4-ad41da12d808
md"""
#### Modelo do Variograma - Azimute
"""

# ╔═╡ 74fd6910-6cbf-11eb-13eb-85d3c632aeaf
md"""

Alcance 1ª Estrutura: $(@bind a_azi1 Slider(10.0:2.0:100.0, default=60.0, show_value=true)) m

Alcance 2ª Estrutura: $(@bind a_azi2 Slider(10.0:2.0:200.0, default=128.0, show_value=true)) m

"""

# ╔═╡ 05c71aa0-6cbf-11eb-3785-3da0793b5308
begin
	
	model_azi0 = NuggetEffect(nugget=c₀)
	
	model_azi1 = SphericalVariogram(sill=Float64(c₁),
									range=Float64(a_azi1))
	
	model_azi2 = SphericalVariogram(sill=Float64(c₂),
									range=Float64(a_azi2))
	
	model_azi = model_azi0 + model_azi1 + model_azi2
	
	plot(γ_azi_1, marker=5, color=:deepskyblue)
	
	plot!(model_azi, 0, 350, title="0$(azi)°",
		  ylims=(0, 0.3), color=:red, lw=2)
	
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
	
	vline!([a_azi2], color="green", ls=:dash, legend=false)
	
end

# ╔═╡ fdf2a9f0-70c1-11eb-3627-6df6c6808da4
md"""---"""

# ╔═╡ b1d58320-6cc1-11eb-1c06-a37cd10649c4
md"""
#### Variograma Experimental - Dip (Maior Continuidade)
"""

# ╔═╡ 58986650-6cc2-11eb-198f-4f39b15c41d8
md"""
Dip: $(@bind dip Slider(0.0:22.5:90.0, default=22.5, show_value=true))°

№ lags: $(@bind nlags_dip Slider(5:1:12, default=10, show_value=true))

Largura de Banda: $(@bind bw_dip Slider(10:10:100, default=70, show_value=true)) m
"""

# ╔═╡ c64daf82-6cc1-11eb-1acf-1db06fb1c44d
begin
	Random.seed!(1234)
	
	γ_dip = DirectionalVariogram(polar2cart(azi,dip), dh_georef,
								 :CU, dtol=bw_dip, maxlag=350,
								 nlags=nlags_dip)

end

# ╔═╡ 8ae327d0-6cc2-11eb-1e64-f9440a711075
begin
	plot(γ_dip, marker=5, ylims=(0, 0.3), color=:deepskyblue,
		 title="$(azi)°/$(dip)°")
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
end

# ╔═╡ 1ba4cd9e-6cc3-11eb-055a-bbefc004eaa9
md"""
#### Modelo do Variograma - Dip (Maior Continuidade)
"""

# ╔═╡ 660072a0-6cc3-11eb-1755-addce896fa8d
md"""

Alcance 1ª Estrutura: $(@bind a_dip1 Slider(10.0:2.0:100.0, default=84.0, show_value=true)) m

Alcance 2ª Estrutura: $(@bind a_dip2 Slider(10.0:2.0:300.0, default=198.0, show_value=true)) m

"""

# ╔═╡ 2ad951fe-6cc3-11eb-2d2e-61b21e39fa03
begin
	
	model_dip0 = NuggetEffect(nugget=c₀)
	
	model_dip1 = SphericalVariogram(sill=Float64(c₁),
									range=Float64(a_dip1))
	
	model_dip2 = SphericalVariogram(sill=Float64(c₂),
									range=Float64(a_dip2))
	
	model_dip = model_dip0 + model_dip1 + model_dip2
	
	plot(γ_dip, marker=5, color=:deepskyblue)
	
	plot!(model_dip, 0, 350, title="$(azi)°/$(dip)°",
		  ylims=(0, 0.3), color=:red, lw=2)
	
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
	
	vline!([a_dip2], color="green", ls=:dash, legend=false)
	
end

# ╔═╡ 02377f90-70c2-11eb-0f0b-df189837f921
md"""---"""

# ╔═╡ 4993c990-6cd8-11eb-38b3-21c034f91b5f
md"""
#### Variogramas Experimentais - Continuidades Intermediária e Menor
"""

# ╔═╡ 1402a9e0-6d8c-11eb-1558-fbf2b9d26659
md"""
Orientações: $(@bind orient Select(["config1" => "177.6°/41.1° e 317.4°/41.1°",
						  			"config2" => "157.5°/00.0° e 247.5°/68.5°",
					  				"config3" => "165.9°/20.4° e 295.3°/59.6°",
					  				"config4" => "198.3°/58.9° e 328.7°/21.3°"]))

№ lags: $(@bind nlags_int_min Slider(5:1:12, default=10, show_value=true))

Largura de Banda: $(@bind bw_int_min Slider(10:10:100, default=70, show_value=true)) m

"""

# ╔═╡ b66138e0-6cd9-11eb-10c8-55281956c83b
begin
	Random.seed!(1234)
	
	azi1, dip1 = 177.6, 41.1
	azi2, dip2 = 317.4, 41.1
	
	if orient == "config1"
		azi1, dip1 = 177.6, 41.1
		azi2, dip2 = 317.4, 41.1
	
	elseif orient == "config2"
		azi1, dip1 = 157.5, 0.0
		azi2, dip2 = 247.5, 68.5
	
	elseif orient == "config3"
		azi1, dip1 = 165.9, 20.4
		azi2, dip2 = 295.3, 59.6
		
	elseif orient == "config4"
		azi1, dip1 = 198.3, 58.9
		azi2, dip2 = 328.7, 21.3
	end
	
	γ_int_min1 = DirectionalVariogram(polar2cart(azi1,dip1),
									  dh_georef, :CU,
									  dtol=bw_int_min, maxlag=250,
									  nlags=nlags_int_min)
	
	γ_int_min2 = DirectionalVariogram(polar2cart(azi2,dip2),
									  dh_georef, :CU,
									  dtol=bw_int_min, maxlag=250,
									  nlags=nlags_int_min)

end

# ╔═╡ b85ab650-6d86-11eb-0146-87a3201f8b18
begin
	plot(γ_int_min1, marker=5, ylims=(0, 0.4), xlims=(0,200),
		 label="$(azi1)°/$(dip1)°", color=:red)
	
	plot!(γ_int_min2, marker=5, ylims=(0, 0.4), xlims=(0,200),
		  label="$(azi2)°/$(dip2)°", color=:deepskyblue,
		  legend=:topright)
	
	hline!([var(dh.CU)], color="gray", ls=:dash, label=false)
	
end

# ╔═╡ b7b00000-6cd9-11eb-1144-e14e2907c721
md"""
#### Modelo do Variograma - Continuidade Intermediária
"""

# ╔═╡ de0e6fc0-6d88-11eb-21a1-a107659e5f43
md"""

Alcance 1ª Estrutura: $(@bind a_interm1 Slider(10.0:2.0:100.0, default=68.0, show_value=true)) m

Alcance 2ª Estrutura: $(@bind a_interm2 Slider(10.0:2.0:170.0, default=136.0, show_value=true)) m

"""

# ╔═╡ dba37dc0-6cd9-11eb-225e-3300e82338c0
begin
	
	model_interm0 = NuggetEffect(c₀)
	
	model_interm1 = SphericalVariogram(sill=Float64(c₁),
									range=Float64(a_interm1))
	
	model_interm2 = SphericalVariogram(sill=Float64(c₂),
									range=Float64(a_interm2))
	
	model_interm = model_interm0 + model_interm1 + model_interm2
	
	plot(γ_int_min1, marker=5, color=:deepskyblue)
	
	plot!(model_interm, 0, 200, title="$(azi1)°/$(dip1)°",
		  ylims=(0, 0.4), color=:red, lw=2)
	
	hline!([var(dh.CU)], color="gray", ls=:dash, legend=false)
	
	vline!([a_interm2], color="green", ls=:dash, legend=false)
	
end

# ╔═╡ efcd8a22-6cd9-11eb-2eb8-c7ef097ec62b
md"""
#### Modelo do Variograma - Menor Continuidade
"""

# ╔═╡ 860da380-6d89-11eb-1e6b-73934e94db2f
md"""

Alcance 1ª Estrutura: $(@bind a_min1 Slider(10.0:2.0:82.0, default=50.0, show_value=true)) m

Alcance 2ª Estrutura: $(@bind a_min2 Slider(10.0:2.0:110.0, default=86.0, show_value=true)) m

"""

# ╔═╡ 0214ccc0-6cda-11eb-13e6-41e668be1e48
begin
	
	model_min0 = NuggetEffect(c₀)
	
	model_min1 = SphericalVariogram(sill=Float64(c₁),
									range=Float64(a_min1))
	
	model_min2 = SphericalVariogram(sill=Float64(c₂),
									range=Float64(a_min2))
	
	model_min = model_min0 + model_min1 + model_min2
	
	plot(γ_int_min2, marker=5, color=:deepskyblue)
	
	plot!(model_min, 0, 200, title="$(azi2)°/$(dip2)°",
		  ylims=(0, 0.4), color=:red, lw=2)
	
	hline!([var(dh.CU)], color="gray", ls=:dash)
	
	vline!([a_min2], color="green", ls=:dash, legend=false)
	
end

# ╔═╡ 1103a530-70c2-11eb-27e1-8757bd6cb16a
md"""---"""

# ╔═╡ 93048530-6d8f-11eb-20a5-a5c67dbe81c9
md"""
#### Representação do Modelo de Variograma Anisotrópico
"""

# ╔═╡ 9d851e70-6d8f-11eb-3ef7-3dab84054680
begin
	
	range_y = range(model_dip)
	range_x = range(model_interm)
	range_z = range(model_min)
	
	plot(model_min, lw=2, label="Menor Continuidade ($(range_z) m)",
		 color=:blue, legend=:bottomright)
	
	plot!(model_interm, lw=2, label="Continuidade Intermediária ($(range_x) m)",
		  color=:green)
	
	plot!(model_dip, lw=2, label="Maior Continuidade ($(range_y) m)",
		  color=:red, xlims=(0.0,350.0), ylims=(0.0,0.25))
	
	
	vline!([range_y], ls=:dash, label=false, color=:red)
	vline!([range_x], ls=:dash, label=false, color=:green)
	vline!([range_z], ls=:dash, label=false, color=:blue)
end

# ╔═╡ c6eb8ac0-6e01-11eb-0875-85a52cc74785
md"""
Podemos adotar a seguinte convenção:

- **Maior Continuidade** = alcance em Y
- **Continuidade Intermediária** = alcance em X
- **Menor Continuidade** = alcance em Z

|Estrutura| Modelo | Alcance em X  | Alcance em Y | Alcance em Z | Variância |Efeito Pepita|
|:-------:|:------:|:-------------:|:------------:|:------------:|:---------:|:-----:|
|    0    |   EPP  |     -         | -            |          -   |     -     | $(c₀) |
|    1    |Esférico|$(a_interm1) m | $(a_dip1) m  | $(a_min1) m  |   $(c₁)   | -     |
|    2    |Esférico| $(range_x) m  | $(range_y) m | $(range_z) m |   $(c₂)   |   -   |
"""

# ╔═╡ 2eb8ee50-70c2-11eb-19ac-9b4736271733
md"""---"""

# ╔═╡ c43deb60-6e0b-11eb-2a08-8b25d9ecad6d
md"""
#### Rotações do variograma

É possível utilizar diversas convenções de rotação de variograma disponíveis na função `aniso2distance()`, disponível no pacote **GeoStats.jl**:

- `:TaitBryanExtr` => rotação *extrínseca* baseada na regra da mão direita:
    - Ordem de rotações: ZXY.
    - Lógica: AH, AH, AH.
    - Radianos.

- `:TaitBryanIntr` => rotação *intrínseca* baseada na regra da mão direita:
    - Ordem de rotação: ZXY.
    - Lógica: AH, AH, AH.
    - Radianos.

- `:EulerExtr` => rotação extrínseca baseada na regra da mão direita:
    - Ordem de rotação: ZXZ.
    - Lógica: AH, AH, AH.
    - Radianos.

- `:EulerIntr` => rotação intrínseca baseada na regra da mão direita:
    - Ordem de rotação: ZXZ.
    - Lógica: AH, AH, AH.
    - Radianos.

- `:GSLIB` => conveção do software GSLIB:
    - Ordem de rotação: ZXY.
    - Lógica: H, AH, AH.
    - Graus.

- `:Leapfrog` => convenção do software Leapfrog:
    - Ordem de rotação: ZXZ.
    - Lógica: H, H, H.
    - Graus.

- `:Datamine` => convenção do software Studio RM:
    - Ordem de rotação: ZXZ.
    - Lógica: H, H, H.
    - Graus.

"""

# ╔═╡ f91d9a80-6e09-11eb-22fc-75f83a6e2013
begin
	rot_z = azi
	
	rot_x = -dip

	if orient == "config1"
		rot_y = -45.0
	elseif orient == "config2"
		rot_y = -0.0
	elseif orient == "config3"
		rot_y = -22.5
	elseif orient == "config4"
		rot_y = -67.5
	end
end;

# ╔═╡ 35c06930-6e0b-11eb-0c5c-2fa0acd69a4c
md"""

O raciocínio utilizado para encontrar as rotações do variograma neste *workflow* segue a lógica da convenção Datamine (ZXY), de acordo com a regra da mão esquerda (Figura 15). Entretanto, como não há essa convenção implementada no pacote, optaremos por utilizar a **convenção do GSLIB** que é muito similar.

"""

# ╔═╡ 6c6fea90-705f-11eb-24ac-990a92d783e3
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_15">
</p>

<p align="center">
	<b>Figura 15</b>: Regra da mão esquerda, utilizada como padrão de rotações de variogramas e volumes de busca no Studio RM.
</p>
"""

# ╔═╡ 6d129330-705f-11eb-03c0-29869e426506
md"""

> **Covenção Datamine (ZXY):**

| Rotação | Eixo | Ângulo   |
|:-------:|:----:|:--------:|
|    1ª   |   Z  |$(rot_z)° |
|    2ª   |   X  |$(-rot_x)°|
|    3ª   |   Y  |$(-rot_y)°|


> **Covenção GSLIB (ZXY):**

| Rotação | Eixo | Ângulo   |
|:-------:|:----:|:--------:|
|    1ª   |   Z  |$(rot_z)° |
|    2ª   |   X  |$(rot_x)° |
|    3ª   |   Y  |$(rot_y)° |

"""

# ╔═╡ 5ca0c410-6ec3-11eb-14a2-ab87f05a3fa7
begin
	
	aniso_elp_1 = aniso2distance([a_dip1, a_interm1, a_min1], 
							     [rot_z, rot_x, rot_y],
							     convention=:GSLIB)
	
	aniso_elp_2 = aniso2distance([range_y, range_x, range_z], 
							     [rot_z, rot_x, rot_y],
							     convention=:GSLIB)
	
end;

# ╔═╡ 3bbeabd0-70c2-11eb-1293-73cf076b5fcf
md"""---"""

# ╔═╡ 8b273fb0-6ec5-11eb-0ebd-f3d33c769b59
md"""
#### Definição do Variograma Anisotrópico

Definida as rotações e alcances do modelo de variograma que será utilizado, podemos construir o variograma anisotrópico (diferentes alcances) que será utilizado na estimativa.
"""

# ╔═╡ 9aa1cdc0-6ec5-11eb-1f87-7d6b1e49536d
begin
	
	γ₀ = NuggetEffect(nugget=c₀)
	
	γ₁ = SphericalVariogram(sill=Float64(c₁),
							distance=aniso_elp_1)
	
	γ₂ = SphericalVariogram(sill=Float64(c₂),
							distance=aniso_elp_2)
	
	γ = γ₀ + γ₁ + γ₂

end;

# ╔═╡ 37b16340-6cd8-11eb-0d5d-29c56bec1d00
html"""<hr><hr>"""

# ╔═╡ d55f70e0-6e46-11eb-3c94-c95a3cdce412
html"""
	<div id="estimativa">

		<h2>7. Estimativa</h2>

	</div>
"""

# ╔═╡ c3c71ff0-6f17-11eb-163b-e5cd9c336409
md"""
#### Introdução

Grande parte das estimativas realizadas na indústria são baseadas em **estimadores lineares ponderados**:

- Esses estimadores são **lineares**, pelo fato serem construídos a partir de uma combinação linear entre valores de unidades amostrais *Z(uᵢ)* e seus respectivos pesos *wᵢ*.

- Esses estimadores são **podenderados**, pelo fato de consistirem em uma média ponderada entre as amostras utilizadas para se estimar um determinado bloco.

Dessa forma, a equação geral dos estimadores lineares ponderados é definida como:

```math
ẑ(uₒ) = \sum_{i=1}^{n} wᵢ.z(uᵢ)
```

São exemplos de estimadores lineares ponderados:

- Inverso da Potência da Distância (*Inverse Power Distance*).

- Vizinho Mais Próximo (*Nearest Neighbor*).

- Krigagem Simples (*Simple Kriging*).

- Krigagem Ordinária (*Ordinary Kriging*).

O que diferencia esses estimadores entre si é a forma como os pesos são calculados.

"""

# ╔═╡ a694fd50-7087-11eb-146e-6d150bca4da2
md"""---"""

# ╔═╡ d5b38670-6f19-11eb-032f-cdb6824ca2a3
md"""
#### Por quê a Krigagem é o Melhor Estimador?

A krigagem é um estimador geoestatístico que usualmente apresenta melhor performance quando comparada a estimadores tradicionais, pois:

- **Considera anisotropia**, pois utiliza as covariâncias associadas ao modelo de variograma como entrada do seu sistema linear.

- **Considera a proximidade entre as amostras**, ou seja, amostras mais próximas tendem a ser mais similares entre si do que amostras mais distantes.

- **Considera a magnitude da continuidade espacial**.

- **Busca estimar a "lei" matemática que descreve o comportamento espacial da variável** a partir dos próprios dados do depósito.

- Leva em consideração a redundância amostral, ou seja, realiza uma **declusterização intrínseca** dos dados, a partir da matriz de desagrupamento (Cᵢⱼ).

- É um **estimador não enviesado** pelo fato da esperança matemática do erro de estimativa ser nula:

```math
ℇ = ẑ(uᵢ) - z(uᵢ)
```
```math
E[ℇ] = 0
```

- É um **estimador ótimo** pelo fato de minimizar a variância do erro σ²(ℇ), por meio do Método dos Mínimos Quadrados Ordinários (*Ordinary Least Square Method*).

- Em suma, a krigagem é um **B.L.U.E.**(*Best Linear Unbiased Estimator*), ou seja, um estimador sem viés, fruto de uma combinação linear que minimiza o erro, atribuindo pesos ótimos às amostras de vizinhança.
"""

# ╔═╡ 1260f192-6f1d-11eb-2a12-b33e08144abe
begin
	Random.seed!(1234)
	
	N₁ = Normal(0, 5)
	N₂ = Normal(0, 1)
	
	high_var = rand(N₁, 1000)
	low_var = rand(N₂, 1000)
	
	histogram(high_var, label="Elevada Dispersão",
		      alpha=0.9, color=:lightblue)
	
	histogram!(low_var, label="Baixa Dispersão",
			   xlabel="Erro (Estimado - Real)",
			   ylabel="Frequência Absoluta",
			   alpha=0.9, color=:white)
	
	vline!([mean(low_var)], color=:red, ls=:solid,
		   label="E[ℇ] = 0", lw=2)
	
end

# ╔═╡ a2cbc050-7087-11eb-14ae-2f5383f2ea91
md"""---"""

# ╔═╡ dd3ce9a0-6f22-11eb-2dac-5b18aa14be35
md"""
#### Krigagem Simples x Krigagem Ordinária

Por serem estimadores lineares ponderados, os estimadores da família da Krigagem apresentam a seguinte forma:

```math
ẑ(u₀) = w₁.z(u₁) + w₂.z(u₂) + w₃.z(u₃) + ... + wₙ.z(uₙ)
```

**Krigagem Simples (KS)**:

- Também denominada Krigagem Estacionária.

- Na Krigagem Simples, a média populacional (μ) é assumida como conhecida e invariável em todo o domínio de estimativa.

- Em outras palavras, esse método assume estacionariedade do domínio, o que é, muitas vezes, improvável, dada a erraticidade dos fenômenos geocientíficos.

- Diferentemente da Krigagem Ordinária, não há condição de fechamento para os pesos atribuídos às amostras da vizinhança e, nesse sentido, uma parte do peso é atribuída à média (μ):

```math
\sum_{i=1}^{n} wᵢ + w(μ) = 1
```

- Exige variogramas estacionários.

**Krigagem Ordinária (KO)**:

- A Krigagem Ordinária não assume o conhecimento da média (μ) e, nesse sentido, a hipótese de estacionariedade para todo o domínio de estimativa não é tão rígida.

- Há condição de fechamento, em que o somatório dos pesos atribuídos às amostras da vizinhança deve resultar em 1. Portanto, não há atribuição de uma parcela do peso de krigagem para a média (μ).

```math
\sum_{i=1}^{n} wᵢ = 1
```

- Essa condição de fechamento é possível a partir da inserção de uma variável artificial no Sistema de Krigagem Ordinária, denominada Parâmetro de Lagrange (ν). A adição dessa nova linha não interfere na condição de igualdade do sistema linear.

"""

# ╔═╡ 9f05deb0-7087-11eb-2b05-cd59b3abf3cb
md"""---"""

# ╔═╡ ab5f6180-6f25-11eb-18aa-c5c2de18eff5
md"""
#### Fluxograma de Estimativa no GeoStats.jl

Abaixo encontra-se o *workflow* para a realização da estimativa via pacote **GeoStats.jl**: 

**1.**  Definição do domínio de estimativa (modelo de blocos):

> **BM = RegularGrid(origin, finish, dims=blocksizes)**

**2.** Definição do problema de estimativa:

> **problem = EstimationProblem(sample, BM, :variable)**

**3.** Criação do *solver*:

> **solver = Kriging(:variable => (variogram = vg_model))**

**4.** Comparação da performance entre os estimadores:

> **performace = error(solver, problem, method(loss=Dict{:CU => lossfunction()}))**

Ou:

> **performace = error(solver, problem, method())**

**5.** Solução do problema:

> **solution = solve(problem, solver)**


"""

# ╔═╡ 97d7f2e0-7087-11eb-2eee-7b59e972786f
md"""---"""

# ╔═╡ d9777220-705f-11eb-139d-ffd779019667
md"""
##### 1. Definição do Modelo de Blocos

Nesta primeira etapa, definimos o domínio de estimativa, ou seja, o modelo de blocos dentro do qual realizaremos a estimativa.

> **BM = RegularGrid(origin, finish, dims=blocksizes)**

Utilizaremos como coordenadas de **origem do modelo de blocos** (canto inferior esquerdo) a seguinte lógica:

> **X₀** = min(X) - XBlockSize

> **Y₀** = min(Y) - YBlockSize

> **Z₀** = min(Z) - ZBlockSize

Utilizaremos como coordenadas do **final do modelo de blocos** (canto superior direito) a seguinte lógica:

> **Xₑ** = max(X) + XBlockSize

> **Yₑ** = max(Y) + YBlockSize

> **Zₑ** = max(Z) + ZBlockSize

Com relação às **dimensões do modelo de blocos**, podemos testar diversas configurações de maneira dinâmica.
"""

# ╔═╡ 859929a2-7064-11eb-3511-a702f424f6af
md"""
Tam. do Bloco em X: $(@bind Xsize Slider(10:5:25, default=20, show_value=true)) m

Tam. do Bloco em Y: $(@bind Ysize Slider(10:5:25, default=20, show_value=true)) m

Tam. do Bloco em Z: $(@bind Zsize Slider(5:5:10, default=10, show_value=true)) m
"""

# ╔═╡ 2587cf30-7064-11eb-2091-f560d74047a1
begin
	Xmin, Xmax = minimum(dh.X), maximum(dh.X)
	Ymin, Ymax = minimum(dh.Y), maximum(dh.Y)
	Zmin, Zmax = minimum(dh.Z), maximum(dh.Z)
	
	origem = ((Xmin - Xsize), (Ymin - Ysize), (Zmin - Zsize))
	final = ((Xmax + Xsize), (Ymax + Ysize), (Zmax + Zsize))
	
	BM = RegularGrid(origem, final, dims=(Xsize, Ysize, Zsize))
	
	plot(BM, camera=(45,45), title="Modelo de Blocos")
	
end

# ╔═╡ 8f389cc0-7087-11eb-2f5f-f5eb7d684aec
md"""---"""

# ╔═╡ 4d999ce0-7066-11eb-0231-ebb200cb7bf5
md"""
##### 2. Definição do Problema de Estimativa

Para definirmos o problema de estimativa, precisamos inserir três parâmetros:

- As **amostras** que serão utilizadas na estimativa (georreferenciadas).

- O **modelo de blocos** em que realizaremos a estimativa.

- A **variável de interesse** que objetivamos estimar.

> **problem = EstimationProblem(sample, BM, :variable)**

Repare que, ao definir o problema de estimativa, são retornadas essas três informações inseridas como parâmetros de entrada.

"""

# ╔═╡ c6ced170-7066-11eb-24bf-efe20f3721e9
problem = EstimationProblem(dh_georef, BM, :CU)

# ╔═╡ 89be0640-7087-11eb-1702-1f6c419797c3
md"""---"""

# ╔═╡ e4fad130-7066-11eb-237c-631c1758c299
md"""
##### 3. Criação dos Solvers

Um **solver** nada mais é do que o estimador que utilizaremos para realizar a estimativa. Atualmente, no pacote **GeoStats.jl**, existem 4 *solvers* de krigagem disponíveis:

- Krigagem Ordinária (OK).

- Krigagem Simples (SK).

- Krigagem Universal (UK).

- Krigagem com Deriva Externa (EDK).

Além dos *solvers* da família da krigagem, existem outros:

- Inverso da Potência da Distância (IDW).

- Regressão Localmente Podenderada (LWR).

- Simulação Gaussiana com Decomposição LU (LUGS).

- Simulação Sequencial Gaussiana (SGS).

- Simulação Gaussiana com FFT (FFTGS).

Neste *workflow* testaremos dois solvers distintos: **SK** e **OK**.

Para a criação do *solver* de **Krigagem Simples**, podemos informar:

- `variogram`: O modelo teórico de variograma (anisotrópico).

- `mean`: A média estacionária (em tese conhecida). Utilizaremos a média de Cu declusterizada.

- `minneighbors`: número mínimo de amostras da vizinhança de krigagem.

- `maxneighbors`: número máximo de amostras da vizinhança de krigagem.

Como informamos a média estacionária, o *solver* `SimpleKriging` é automaticamente reconhecido.

Para a criação do *solver* de **Krigagem Ordinária**, podemos informar:

- `variogram`: O modelo teórico de variograma (anisotrópico).

- `minneighbors`: número mínimo de amostras da vizinhança de krigagem.

- `maxneighbors`: número máximo de amostras da vizinhança de krigagem.

Como informamos apenas o modelo de variograma, o *solver* `OrdinaryKriging` é automaticamente reconhecido.

"""

# ╔═╡ 4ce20fe0-706a-11eb-3ecf-d734f9f53e8e
md"""
№ mínimo de amostras: $(@bind s_min Slider(2:1:6, default=4, show_value=true))

№ máximo de amostras: $(@bind s_max Slider(6:1:20, default=8, show_value=true))

"""

# ╔═╡ d60c1d80-7068-11eb-10c1-8f4071a8024f
begin
	μ = mean(dh_georef, :CU)
	
	SK = Kriging(
				 :CU => (variogram=γ,
						 mean=μ,
		                 minneighbors=s_min,
			             maxneighbors=s_max)
		                )
	
	OK = Kriging(
				 :CU => (variogram=γ,
			             minneighbors=s_min,
			             maxneighbors=s_max)
		                )
	  
end

# ╔═╡ 8291a110-7087-11eb-2ea3-9525931c80b2
md"""---"""

# ╔═╡ bb43fa80-706e-11eb-3dbe-498a6be4adf4
md"""
##### 4. Comparação da Performance entre os Estimadores

Antes mesmo de executar a estimativa propriamente dita, podemos realizar uma comparação da performance entre os estimadores. Em outras palavras, podemos avaliar qual estimador apresenta o menor erro, ou seja, a melhor performance.

Para tal, devemos definir o **método** e a **métrica** de validação de performance.

No pacote **GeoStats.jl**, a avaliação de performance é realizada da seguinte maneira:

> **performace = error(solver, problem, method(loss=Dict{:CU => lossfunction()}))**

"""

# ╔═╡ 1fd0fa90-7086-11eb-3db1-8552de51cb38
md"""
###### Métodos de Validação de Performance

Para realizarmos a a análise da performance de um estimador, podemos utilizar diversos **métodos de validação**, como:

- **Leave One Out**.

- **Leave Ball Out**.

- **Block Cross Validation**.

Neste treinamento, utilizaremos o **Leave One Out**, também conhecido como **Validação Cruzada** no universo da geoestatística. Esse método consiste em eliminar uma amostra do *dataset* por vez e realizar a sua estimativa (Figura 16). Dessa forma, podemos ter uma ideia da permormance do estimador.

"""

# ╔═╡ d02aa01e-706e-11eb-3deb-2ffa303731f2
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_16">
</p>

<p align="center">
	<b>Figura 16</b>: Esquema ilustrativo da validação cruzada (<i>Leave One Out</i>).
</p>
"""

# ╔═╡ 621935c0-7086-11eb-0e7f-eb59845a0faa
md"""
###### Métricas de Avaliação de Performance (Loss Functions)

Além disso, podemos especificar a métrica que utilizaremos para quantificar o erro associado ao estimador. Essas **métricas** são comumente chamadas de **Funções de Perda** (*Loss Functions*). Todas essas métricas estão disponíveis no pacote **LossFunctions.jl**. Algumas funções de perda são:

- **Mean Square Error (MSE) / L2 Loss**:

    - Erro médio quadrático.
    - O resultado não é informado na escala da variável
        - Ex.: Se a variável estimada é Cu (%), o erro médio quadrático é informado em %².
    - Essa função de perda penaliza muito estimativas muito distantes dos valores reais (o erro é quadrático!). 

```math

MSE = \frac{1}{n} \sum_{i=1}^{n} (z(uᵢ) - ẑ(uᵢ))^2

```

- **Root Mean Square Error (RMSE)**:

    - É simplesmente a raíz do erro médio quadrático.
    - O resultado é informado na escala da variável.

```math

RMSE = \sqrt{MSE}

```

- **Mean Absolute Error (MAE) / L1 Loss**:

    - É o erro médio absoluto.
    - O erro também é informado na escala da variável.
    - Como o erro não é quadrático, não há uma penalização tão grande de estimativas muito distantes dos seus respectivos valores reais, como ocorre via MSE.

```math

MAE = \frac{1}{n} \sum_{i=1}^{n} |z(uᵢ) - ẑ(uᵢ)|

``` 

"""

# ╔═╡ 7a073d10-7088-11eb-1930-519022040b80
begin
	
	# Avaliação de performance da Krigagem Simples:
	
	## MSE
	Raw_MSE_SK = error(
		               SK,
		               problem,
		               LeaveOneOut(loss=Dict(:CU => L2DistLoss()))
		              )[:CU]
	
	MSE_SK = round(Raw_MSE_SK, digits=4)
	
	
	## RMSE
	Raw_RMSE_SK = √(MSE_SK)
	
    RMSE_SK = round(Raw_RMSE_SK, digits=4)	
	
	
	## MAE
	Raw_MAE_SK = error(
		               SK,
		               problem,
		               LeaveOneOut(loss=Dict(:CU => L1DistLoss()))
		              )[:CU]
	
	MAE_SK = round(Raw_MAE_SK, digits=4)
	
	
	
	# Avaliação da performance da Krigagem Ordinária:
	
	## MSE
	Raw_MSE_OK = error(
		               OK,
		               problem,
		               LeaveOneOut(loss=Dict(:CU => L2DistLoss()))
		              )[:CU]
	
	MSE_OK = round(Raw_MSE_OK, digits=4)
	
	
	## RMSE
	Raw_RMSE_OK = √(MSE_OK)
	
    RMSE_OK = round(Raw_RMSE_OK, digits=4)
	

	## MAE
	Raw_MAE_OK = error(
		               OK,
		               problem,
		               LeaveOneOut(loss=Dict(:CU => L1DistLoss()))
		          )[:CU]
	
	MAE_OK = round(Raw_MAE_OK, digits=4)
	
end;

# ╔═╡ 4e5054d0-7089-11eb-356d-c13ea1f19ee7
md"""

|Solver| MSE(%²) |  RMSE(%) |  MAE(%) |
|:----:|:-------:|:--------:|:-------:|
|  SK  |$(MSE_SK)|$(RMSE_SK)|$(MAE_SK)|
|  OK  |$(MSE_OK)|$(RMSE_OK)|$(MAE_OK)|

"""

# ╔═╡ 60b568c0-70c2-11eb-00fc-2702cc297bcb
md"""---"""

# ╔═╡ 7924b62e-7091-11eb-0150-0d4cd784eb7f
md"""
##### 5. Solução do Problema de Estimativa

Para finalmente estimar os teores de Cu, podemos utilizar a função `solve()`, disponível no pacote **GeoStats.jl**. Nesse sentido, podemos passar como argumentos o **problema de estimativa** e o **solver** que será utilizado para resolvê-lo:

> **solution = solve(problem, solver)**

Como as performances dos estimadores escolhidos (*i.e.*, SK e OK) foram muito semelhantes, iremos estimar os teores de Cu de ambas as formas:

"""

# ╔═╡ e7d77560-7094-11eb-1eda-8fb4b7457860
begin
	estim_SK = solve(problem, SK)
	
	estim_OK = solve(problem, OK)
end;

# ╔═╡ ef215fc0-6e46-11eb-1804-d5f302cb9402
html"""<hr><hr>"""

# ╔═╡ e2580f00-6e46-11eb-21c8-a59b678acc9b
html"""
	<div id="validacao_da_estimativa">

		<h2>8. Validação da Estimativa</h2>

	</div>
"""

# ╔═╡ 4f2c5290-70ad-11eb-2871-4bcc5ee5a3f1
md"""

Uma etapa crucial do fluxograma de estimativa de recursos é a **validação da estimativa**. Dentre as diversas formas existentes, realizaremos as seguintes validações:

- Validação global da estimativa.

- Q-Q Plot entre teores amostrais e teores estimados.

- Inclinação da reta de regressão entre teores amostrais e teores estimados.

"""

# ╔═╡ 6a028b10-70c2-11eb-337d-f79d7c5a4c08
md"""---"""

# ╔═╡ 927e1910-70ae-11eb-1eb1-bbaf8d8f3f0a
md"""
##### Validação Global da Estimativa

Nesta validação, nos atentaremos para a comparação entre os seguintes sumários estatísticos das seguintes variáveis:

- Cu amostral.
- Cu declusterizado.
- Cu estimado por SK.
- Cu estimado por OK.

É importante ressaltar dois pontos acerca dos estimadores da família da krigagem:

- Sabe-se que a **krigagem** considera a redundância amostral e, consequentemente, **realiza uma declusterização intrínseca**. Nesse sentido, se comparamos a média amostral do Cu (não desagrupada) com a média estimada via krigagem, teremos uma falsa impressão de subestimativa. Por outro lado, é de se esperar que a **média estimada** por krigagem seja **semelhante à média amostral desagrupada/declusterizada**.

- Em geral, a estimativa por **krigagem não honra a distribuição estatística** (histograma) **dos teores amostrais**. Nesse sentido, o **histograma dos teores estimados** por krigagem tende a ser **mais suavizado** do que o histograma dos teores amostrais. Em outras palavras, há uma redução na dispersão quando fazemos uma comparação entre os teores amostrais e os teores estimados. Portanto, a **krigagem tende a "mascarar" as reais heterogeneidades presentes em um depósito mineral**.

"""

# ╔═╡ 4a62c520-70c4-11eb-3b01-7509ea0780db
md""" ###### Sumário estatístico comparativo """

# ╔═╡ 2b7c00e2-70c4-11eb-1d32-a78febc6988e
md""" ###### Histograma SK """

# ╔═╡ 3e940100-70c4-11eb-2d44-85cf1f1ee510
md""" ###### Histograma OK """

# ╔═╡ af3987f2-70a5-11eb-3823-35a58b5168d3
begin
	real = values(dh_georef)[:,:CU]
	estimado_SK = values(estim_SK)[:,:CU]
	estimado_OK = values(estim_OK)[:,:CU]
	
	histogram(real, label="Cu Amostral", alpha=0.75)
	histogram!(estimado_OK, label="Cu OK", alpha=0.50,
			   xlabel="Cu (%)", ylabel="Frequência Absoluta")
	
end

# ╔═╡ 7a30dac0-70ac-11eb-3f3a-a39482d6db94
begin
	
	q_SK = quantile(estimado_SK, [0.1,0.25,0.5,0.75,0.9])
	q_OK = quantile(estimado_OK, [0.1,0.25,0.5,0.75,0.9])
	
	sum_SK = DataFrame(
							Variável = :CU_SK,
							X̅ = round(mean(estimado_SK), digits=2),
							S² = round(var(estimado_SK), digits=2),
							S = round(std(estimado_SK), digits=2),
							P10 = round(q_SK[1], digits=2),
							P25 = round(q_SK[2], digits=2),
							P50 = round(q_SK[3], digits=2),
							P75 = round(q_SK[4], digits=2),
							P90 = round(q_SK[5], digits=2)
						  )
	
	sum_OK = DataFrame(
							Variável = :CU_OK,
							X̅ = round(mean(estimado_OK), digits=2),
							S² = round(var(estimado_OK), digits=2),
							S = round(std(estimado_OK), digits=2),
							P10 = round(q_OK[1], digits=2),
							P25 = round(q_OK[2], digits=2),
							P50 = round(q_OK[3], digits=2),
							P75 = round(q_OK[4], digits=2),
							P90 = round(q_OK[5], digits=2)
					  )
	
	vcat(sum_cu[:, [:Variável, :X̅, :S², :S, :P10, :P25, :P50, :P75, :P90]],
	 sum_dec,
	 sum_SK,
	 sum_OK)
end

# ╔═╡ 737c1490-70c2-11eb-3871-f52255abe25d
begin

	histogram(real, label="Cu Amostral", alpha=0.75)
	
	histogram!(estimado_SK, label="Cu SK", bins=80,
			   alpha=0.50,
			   xlabel="Cu (%)", ylabel="Frequência Absoluta")
	
	vline!([μ], color=:red, ls=:dashdot, lw=2, label="μ")
	
end

# ╔═╡ bb66b990-70c2-11eb-229d-29b5c6bbb953
md"""---"""

# ╔═╡ 197655c0-70b1-11eb-15f0-33a676325c4d
md"""
##### Q-Q Plot - Teores Amostrais x Teores Estimados

O Q-Q Plot entre os teores amostrais (reais) e os teores estimados pode ser utilizado para realizar uma comparação entre as distribuições estatística de Cu amostral e Cu estimado. Em outras palavras, podemos **analisar (qualitativamente) o grau de suavização da estimativa por krigagem**.

Nesse sentido, quanto mais os **pontos se aproximam da reta X=Y** do Q-Q Plot, **menor** é o efeito de **suavização**.

Por outro lado, quanto mais os **pontos tendem a se horizontalizar**, **maior** é o grau de **suavização** da estimativa por krigagem.

"""

# ╔═╡ 27b6aa60-7096-11eb-0540-5345b4adef0e
begin
	
	qq_SK = qqplot(real, estimado_SK,
				   xlabel="Cu", ylabel="Cu_OK",
				   color=:red, label=false,
				   title="Amostral x Estimado (SK)",
				   legend=:topleft)
	
	hline!([μ], color=:gray, label="μ", ls=:dash)
	
	
	qq_OK = qqplot(real, estimado_OK,
				   xlabel="Cu", ylabel="Cu_OK",
				   color=:green, label=false,
				   title="Amostral x Estimado (OK)")
	
	plot(qq_SK, qq_OK)
	
end

# ╔═╡ c4806fd2-70c2-11eb-2018-896eebbc6678
md"""---"""

# ╔═╡ 4ba4ae40-70b4-11eb-2e77-ad23fd5b4b05
md"""

##### Inclinação da Reta de Regressão - Teores Amostrais x Teores Estimados

Uma outra forma de analisar (semi-quantitativamente) o grau de suavização da estimativa é a partir da obtenção da **inclinação da reta de regressão** entre os teores amostrais e os teores estimados por krigagem.

A Figura 17 ilustra essa situação que, por sua vez, é muito semelhante à análise realizada via Q-Q Plot. Nesse sentido:

- Valores de **inclinação ~ 1.0** indicam um **grau de suavização mínimo** da estimativa. Portanto, os teores estimados honram mais as reais heterogeneidades do depósito.

- Valores de **inclinação ~ 0.0** sugerem um **efeito de suavização extremo**, ou seja, uma redução drástica da dispersão dos teores estimados quando comparados com os teores amostrais.

"""

# ╔═╡ 694fa1b0-70b5-11eb-1a5a-a7229cbce5af
html"""
<p align="center">
	<img src="Caminho/Da/Figura XX.png" alt="Figura_17">
</p>

<p align="center">
	<b>Figura 17</b>: Relação entre a inclinação da reta de regressão e o grau de suavização da estimativa por krigagem (Disponível em: <a href="https://snowdengroup.com/news/supervisor-8-7-multi-block-kriging-neighbourhood-analysis/">Snowden Group<a/>).
</p>
"""

# ╔═╡ c17682a2-70ab-11eb-25df-4d24e77bca3d
md"""
###### Inclinação da Reta de Regressão (SK)
"""

# ╔═╡ b8c3c530-70a3-11eb-3c92-8d9d91a6899a
begin
	
	qs = range(0.0,1.0, step=0.0001) |> collect
	
	mtx_SK = hcat(quantile(real, qs), quantile(estimado_SK, qs))
	
	df_SK = DataFrame(CU=mtx_SK[:,1], CU_SK=mtx_SK[:,2])
	
	ols_SK = lm(@formula(CU_SK ~ CU), df_SK)
	
end

# ╔═╡ 14047c60-70b2-11eb-102f-db6edc6c3dd8
md""" A inclinação da reta de regressão da **SK** é igual a **$(round(coef(ols_SK)[2], digits=2))**."""

# ╔═╡ d577aa40-70ab-11eb-3b91-7df7158f3dba
md"""
###### Inclinação da Reta de Regressão (OK)
"""

# ╔═╡ f817d690-6e46-11eb-04e1-bf2ec2655a32
html"""<hr><hr>"""

# ╔═╡ 68ec2f80-70b6-11eb-28fe-f7bc1eadd63d
html"""
	<div id="exportacao">

		<h2>9. Exportação dos Dados Estimados</h2>

	</div>
"""

# ╔═╡ bedb8310-70c4-11eb-115b-a5b2f9b05ea7
md"""

Por fim, podemos **exportar os resultados da estimativa** como um **arquivo** do tipo **CSV**, com as seguintes colunas:

- `X`: coordenada X do centroide do bloco.

- `Y`: coordenada Y do centroide do bloco.

- `Z`: coordenada Z do centroide do bloco.

- `CU_OK`: Cu estimado por Krigagem Ordinária.

"""

# ╔═╡ d7d1c5e0-70b6-11eb-022b-8788a82085e4
begin
	coordenadas = DataFrame(X = coordinates(estim_OK)[1,:],
							Y = coordinates(estim_OK)[2,:],
							Z = coordinates(estim_OK)[3,:]
						   )
	
	CU_OK = DataFrame(CU_OK = values(estim_OK)[:,1])
	
	df_final = hcat(coordenadas, CU_OK)
	
	first(df_final, 5)
	
	#CSV.write("modelo_estimado.csv", df_final)
	
end

# ╔═╡ c1b76060-70a4-11eb-389e-69d56b899820
begin
	
	mtx_OK = hcat(quantile(real, qs), quantile(estimado_OK, qs))
	
	df_OK = DataFrame(CU=mtx_OK[:,1], CU_OK=mtx_OK[:,2])
	
	ols_OK = lm(@formula(CU_OK ~ CU), df_OK)

end

# ╔═╡ a1be8780-70b2-11eb-0f1d-1f27e962316f
md""" A inclinação da reta de regressão da **OK** é igual a **$(round(coef(ols_OK)[2], digits=2))**."""

# ╔═╡ d602dbd0-70c2-11eb-1722-335f1b7045b6
html"""<hr><hr>"""

# ╔═╡ 8a3dae00-6e4c-11eb-0d6c-2d6b4e28112e
html"""
	<div id="recomendacoes">

		<h2>10. Recomendações</h2>

		<p> Caso se interesse por aprender mais sobre a linguagem <a href="https://docs.julialang.org/en/v1/">Julia</a>, confira as documentações de alguns pacotes amplamente utilizados atualmente! </p>

	</div>
"""

# ╔═╡ 03be6f10-673d-11eb-3938-99159c46b44c
html"""
<table>
	<tr>
		<th>Pacote</th>
		<th>Nativo</th>
		<th>Descrição</th>
	</tr>
	<tr>
		<td><b>
			<a href="https://docs.julialang.org/en/v1/stdlib/Statistics/">Statistics</a>
		<td style="text-align: center;">Sim</td>
		<td>Funcionalidades básicas de estatística</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://docs.julialang.org/en/v1/stdlib/Random/">Random</a>
		<td style="text-align: center;">Sim</td>
		<td>Geração de números aleatórios</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/">LinearAlgebra</a>
		<td style="text-align: center;">Sim</td>
		<td>Operações de Álgebra Linear</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliaearth.github.io/GeoStats.jl/stable/index.html">GeoStats</a>
		<td style="text-align: center;">Não</td>
		<td>Ferramentas de geoestatística e aprendizado geoestatístico</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliahub.com/docs/DrillHoles/XEHc3/0.1.0/">DrillHoles</a>
		<td style="text-align: center;">Não</td>
		<td>Geração de furos e compositagem ao longo do furo</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://csv.juliadata.org/stable/">CSV</a>
		<td style="text-align: center;">Não</td>
		<td>Manipulação de dados em formato CSV</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://dataframes.juliadata.org/stable/">DataFrames</a>
		<td style="text-align: center;">Não</td>
		<td>Manipulação de dados tabulares</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://julia-data-query.readthedocs.io/en/latest/dplyr.html#">DataFramesMeta</a>
		<td style="text-align: center;">Não</td>
		<td>Manipulação de dados tabulares</td>
	</tr>
	<tr>
		<td><b>
			<a href="http://www.queryverse.org/Query.jl/stable/">Query</a>
		<td style="text-align: center;">Não</td>
		<td>Realização de consultas (queries)</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://github.com/JuliaStats/Distances.jl">Distances</a>
		<td style="text-align: center;">Não</td>
		<td>Cálculo eficiente de distâncias entre vetores</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliastats.org/Distributions.jl/stable/">Distributions</a>
		<td style="text-align: center;">Não</td>
		<td>Distribuições de probabilidade e funções relacionadas</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliastats.org/StatsBase.jl/stable/">StatsBase</a>
		<td style="text-align: center;">Não</td>
		<td>Funções estatísticas básicas</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliapackages.com/p/statsplots">StatsPlots</a>
		<td style="text-align: center;">Não</td>
		<td>Visualização de dados</td>
	</tr>
	<tr>
		<td><b>
			<a href="http://docs.juliaplots.org/latest/">Plots</a>
		<td style="text-align: center;">Não</td>
		<td>Visualização de dados</td>
	</tr>
	<tr>
		<td><b>
			<a href="http://gadflyjl.org/stable/index.html">Gadfly</a>
		<td style="text-align: center;">Não</td>
		<td>Visualização de dados (inspirada no ggplot2)</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://www.queryverse.org/VegaLite.jl/stable/">VegaLite</a>
		<td style="text-align: center;">Não</td>
		<td>Visualização de dados</td>
	</tr>
	<tr>
		<td><b>
			<a href="http://makie.juliaplots.org/stable/">Makie</a>
		<td style="text-align: center;">Não</td>
		<td>Visualização de dados</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliaimages.org/stable/">Images</a>
		<td style="text-align: center;">Não</td>
		<td>Processamento de imagens</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliahub.com/docs/PlutoUI/abXFp/0.6.3/">PlutoUI</a>
		<td style="text-align: center;">Não</td>
		<td>Implementação da tag <i>input</i> no ambiente Julia</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliastats.org/GLM.jl/v1.1/">GLM</a>
		<td style="text-align: center;">Não</td>
		<td>Modelos lineares e lineares generalizados</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://scikitlearnjl.readthedocs.io/en/latest/">ScikitLearn</a>
		<td style="text-align: center;">Não</td>
		<td>Modelos de Machine Learning (semelhante ao sklearn do Python)</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://fluxml.ai/Flux.jl/stable/">Flux</a>
		<td style="text-align: center;">Não</td>
		<td>Modelos de Machine Learning</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://github.com/JuliaPy/PyCall.jl">PyCall</a>
		<td style="text-align: center;">Não</td>
		<td>Importação de pacotes do Python</td>
	</tr>
	<tr>
		<td><b>
			<a href="https://juliainterop.github.io/RCall.jl/v0.6.0/index.html">RCall</a>
		<td style="text-align: center;">Não</td>
		<td>Importação de pacotes do R</td>
	</tr>
	
</table>
"""

# ╔═╡ dfbc2d70-70c2-11eb-03e0-2b5748d95770
html"""<hr><hr>"""

# ╔═╡ c16cd0f0-69a0-11eb-39e3-49c4e9bf7a4e
html"""
	<div id="referencias">

		<h2>11. Referências</h2>

	</div>
"""

# ╔═╡ cc88e6e0-69a0-11eb-14fb-1f10262af8d7
html"""
	<p style="text-align: justify;">
		Abzalov, M., 2016. Applied mining geology (Vol. 12). Cham: Springer International Publishing.
	</p>
	<p style="text-align: justify;">
		Deutsch, J. L., 2015. Experimental variogram tolerance parameters. In: J. L. Deutsch (Ed.), Geostatistics Lessons. Retrieved from: <i>http://geostatisticslessons.com/lessons/variogramparameters</i>.
	</p>

	<p style="text-align: justify;">
		Isaaks, E. H., & Srivastava, M. R., 1989. Applied geostatistics (No. 551.72 ISA).
	</p>

	<p style="text-align: justify;">
		Pyrcz, M. J., Gringarten, E., Frykman, P., & Deutsch, C. V., 2006. Representative input parameters for geostatistical simulation.
	</p>

	<p style="text-align: justify;">
		Rossi, M. E., & Deutsch, C. V., 2013. Mineral resource estimation. Springer Science & Business Media.
	</p>

	<p style="text-align: justify;">
		Sinclair, A. J., & Blackwell, G. H., 2006. Applied mineral inventory estimation. Cambridge University Press.
	</p>

	<p style="text-align: justify;">
		Yamamoto, J. K., 2001. Avaliação e classificação de reservas minerais (Vol. 38). Edusp.
	</p>


"""

# ╔═╡ Cell order:
# ╟─343834a2-668e-11eb-2533-6fb672c854b2
# ╟─7a2a5310-6690-11eb-3624-b1b66e094059
# ╟─53ab7a10-6691-11eb-0a2c-0f0588db91ea
# ╟─9b1f7ff0-6ba9-11eb-3111-658a4692059c
# ╟─c887b4c0-6691-11eb-15aa-c9293a19980c
# ╠═d45e5ff2-6ba6-11eb-3574-6ff6768570d5
# ╟─34ef7a70-6972-11eb-324e-1d1ee39240fc
# ╟─0ba43cd0-6ba9-11eb-2d22-c7fa0e0911cc
# ╟─c61f62e0-6737-11eb-2ad9-7dab5d0bd0c5
# ╟─889f92f0-673c-11eb-0364-f54810567214
# ╟─c8ebce50-6971-11eb-01fd-adf537723fb9
# ╟─71408b30-6e4b-11eb-1c70-e746d0ffa359
# ╟─a11acb9e-699a-11eb-38ee-45c0f768a1a3
# ╟─33e94850-6e44-11eb-1d23-1bcec1d9ab94
# ╟─02996b20-70c1-11eb-2434-a592600949de
# ╟─9394a8a0-699c-11eb-2852-f5f450a869b8
# ╟─f54ccf10-6748-11eb-20b2-418a5d38f613
# ╟─71e44170-6749-11eb-2c46-ed3e09bbba6b
# ╟─93d7ecfe-6748-11eb-2b92-05ad9da17816
# ╟─89801c00-6749-11eb-2150-83ca5080cfa9
# ╟─97126210-6749-11eb-1458-f3b233eeccfd
# ╟─1e5cb230-6753-11eb-2c5a-47635839ae47
# ╟─42060790-6753-11eb-2674-6d09047846d7
# ╟─4349cb70-6972-11eb-3b68-071d7b8e4af7
# ╟─d6c57740-6e4b-11eb-351f-cd78f069bea7
# ╟─7fb29332-6756-11eb-23df-fda7421f6559
# ╟─ef3ef810-699f-11eb-342d-b97fb146d03f
# ╟─e16b7bc0-6759-11eb-292c-e15b4a1d845e
# ╟─c92611c0-67bc-11eb-1dad-f998543a00e9
# ╟─1af5b540-675a-11eb-0cec-bf86a16706e2
# ╟─d949bed0-67c1-11eb-1598-d192d8f06f1e
# ╟─0d473630-67be-11eb-36ea-dfe7ddc63b10
# ╟─ee463560-67cc-11eb-27ec-a77d3f1d7fe9
# ╟─00479350-68a7-11eb-0b15-770340616ebd
# ╟─fe1cc620-67cc-11eb-20b7-1b974ff48ae4
# ╟─fdaadbc0-681f-11eb-290c-e5a47afa6b1d
# ╟─16836ed0-694e-11eb-22f6-11f66381b342
# ╟─9b3c0620-681b-11eb-2039-0b90437c77b5
# ╟─4f45323e-681c-11eb-337e-9f57be991302
# ╟─3350fa10-681c-11eb-1843-f72bb73520c7
# ╟─b24a4730-694e-11eb-22e8-8becd4e846e8
# ╟─f3e973d0-681f-11eb-2916-87436e59189a
# ╟─6a4ebf80-6820-11eb-0239-dfefc4c9cbbd
# ╟─2ca51d40-6821-11eb-3d3d-813ebfb191c2
# ╟─e0503da0-694f-11eb-040e-79eb6bae7f94
# ╟─9ac58ee0-6821-11eb-23ba-afdc622aea47
# ╟─af5b5560-6821-11eb-1027-4d4eff83fb49
# ╟─aeff2ba0-6821-11eb-098b-4745596c78b0
# ╟─34dbeae0-6950-11eb-3ce0-39769f66899f
# ╟─aaff8c20-6970-11eb-0c6a-7b65b7eb60af
# ╟─9324f930-6823-11eb-2801-6b6a6e9c932e
# ╟─3f187220-6893-11eb-3400-fdceb2722f8f
# ╟─5f0452d0-696e-11eb-0153-6d79a5b2c877
# ╟─9d435950-6893-11eb-17b4-137a29920220
# ╟─7b5acf40-696e-11eb-3622-b34aac8e92a9
# ╟─5531f270-6893-11eb-0f9c-6f75892042bb
# ╟─86b3ee32-696e-11eb-37dd-552fe42a39d6
# ╟─790998e0-6895-11eb-11ee-315f5809f7ec
# ╟─a2adf2be-696e-11eb-0461-073da1fd9940
# ╟─16a9abd0-689b-11eb-21e8-59aa875336db
# ╟─b8d61910-696e-11eb-22b5-fd8a6637ada1
# ╟─99964d70-6970-11eb-3f68-9193cb05bde5
# ╟─15168ae0-68aa-11eb-1169-03ba57fba5ee
# ╟─3ef3a2b0-68ac-11eb-11d4-9f86c0bc55eb
# ╟─6eaf66d0-68aa-11eb-3447-8778ee384000
# ╟─c74d81b2-68ef-11eb-2e46-c15d3dc8417d
# ╟─d0b39e50-68af-11eb-0f57-27c2eda82e04
# ╟─dea62cce-68af-11eb-38f5-3163f2812fdf
# ╟─9eb1d8a0-68ef-11eb-2f89-094b93fe487b
# ╟─8ab36b92-68ac-11eb-3d40-2f2b68531855
# ╟─bbc9fd60-68ad-11eb-2719-c9bfcc5d96c3
# ╟─5b177af0-68ef-11eb-2ea4-f59094b4fa51
# ╟─0cb77fc0-6973-11eb-2eca-017927d15a8e
# ╟─4f0f1cf0-68b2-11eb-08d8-e32e50cc5708
# ╠═edbbb020-68b2-11eb-3797-5f84caa35b9e
# ╠═f14a3690-698d-11eb-0a3f-3f28c067f035
# ╠═f243ffe0-698d-11eb-1c71-05f50abc7fd4
# ╟─3896bbe0-6943-11eb-3cbd-adbb2c7c0026
# ╟─8880f180-6f0a-11eb-1fb4-d5354b342647
# ╟─4a962ac0-6f0f-11eb-375f-61b6de91bebe
# ╟─829a6080-6f0f-11eb-1d3c-b9d97d41a225
# ╟─f882c1c0-6f14-11eb-0570-fb2d9a4da191
# ╟─fb1a2040-6947-11eb-209c-75ac9ef76a37
# ╟─17437230-6948-11eb-3cee-59ff37e5dc2f
# ╟─2da964d0-6948-11eb-3297-0d38b3f76f6e
# ╟─82c2ec70-6943-11eb-0208-a3287d596807
# ╟─dfb2a240-6948-11eb-2b98-f9b70c96340b
# ╟─ae093bc0-6946-11eb-2ffd-374f53bedf86
# ╟─e7e21560-6991-11eb-1c07-99dd7413b3a7
# ╟─6e80e0b0-6942-11eb-3dac-1be7a41ff31d
# ╟─10dad9f0-698f-11eb-170a-e56e35e77dca
# ╟─8fe3b4d0-68bb-11eb-1ae9-7beb74163940
# ╟─43c02040-68eb-11eb-383d-e710b0a50fcf
# ╟─43b99380-698e-11eb-1289-b5907ecc753e
# ╟─47768810-6d4a-11eb-2a19-9d348e6117ae
# ╟─7580b9b0-6d4a-11eb-0b5e-9981665d3e41
# ╠═8ec82160-6d4a-11eb-004e-1b0519e69a41
# ╟─2bf23340-6d4b-11eb-0801-abda77ea2c34
# ╠═d21ee65e-6d4a-11eb-11f2-370349470005
# ╟─6dc940a0-6d4c-11eb-366a-e7d1400bb0dd
# ╟─2a87f4e0-6d4b-11eb-1e9a-ada1e626fa68
# ╟─182879de-6d4c-11eb-19aa-f13d3b658689
# ╟─b844ce00-694c-11eb-1300-ad41289f63a1
# ╟─92738660-698a-11eb-1f33-894a5df007a8
# ╟─9d85ff60-698a-11eb-0487-a1d94d457220
# ╟─aac3a530-6d4d-11eb-085d-1bab15c19010
# ╟─92908910-6e10-11eb-381a-51d5a94c7da7
# ╟─1c473190-6e57-11eb-0688-ed685c6d4080
# ╟─26c5c7a0-6e5a-11eb-2e60-cfc5dcac3aaa
# ╟─53f60710-6e25-11eb-13c8-dba3ac9d77aa
# ╟─a035e1f0-6e10-11eb-2583-3f69db55f2df
# ╟─4b581080-6e25-11eb-2af9-1364ad8550de
# ╟─03614a70-6e0d-11eb-168c-e534b1963bdc
# ╟─3f360c00-6e14-11eb-0b61-f19f312af7cc
# ╟─e697a030-6e14-11eb-0740-bd7efaef212a
# ╟─d39e0810-6e15-11eb-26fa-cb8dc416efdf
# ╟─41366022-6e25-11eb-2f5f-e326ca201f8c
# ╟─608b68d0-6e20-11eb-07f2-a9bc08859292
# ╟─036adad0-6e22-11eb-08eb-83e628823098
# ╟─924c4eee-6e22-11eb-1906-3d5589077bc7
# ╟─492eb2be-6e23-11eb-09af-7bf51a7ef5ec
# ╟─27d99bb0-6e25-11eb-2ada-efd7d4d70e75
# ╟─b5f37a0e-6e25-11eb-1489-11ab0855526c
# ╟─3399c460-6e26-11eb-01f7-dd20d15d4225
# ╟─654d9d10-6e26-11eb-3cdd-e974e3decbc5
# ╟─6c79db30-6e26-11eb-00fd-49afdf7a366a
# ╟─60a38f70-6e46-11eb-20c4-0b0594eb96a0
# ╟─b42030d0-6d4d-11eb-36ff-33e5dddea922
# ╟─8125afd0-6e28-11eb-0e6a-a75e65e0bf92
# ╟─6daa5e60-6e46-11eb-1c8e-afd6295a2c54
# ╟─3688b4b0-6e2b-11eb-1dce-2119db7856b7
# ╠═38876380-6e2e-11eb-09fc-bd56e6f1aee8
# ╟─e3eadb70-6e2f-11eb-1c38-0bfc615d6559
# ╟─49ee4650-6e30-11eb-0f73-cb0ead7f16c6
# ╟─88a828a0-6e46-11eb-39a0-b75f488c730a
# ╟─6ee37970-6e2c-11eb-001e-bb716b10fb40
# ╟─366c9270-6e31-11eb-20fe-9b45627cfcaa
# ╟─91e03c50-6e46-11eb-047b-59a78ffec642
# ╟─ebc5d780-6e2c-11eb-3ceb-7d1b08e93828
# ╟─3db6dee2-6e3c-11eb-275a-cbe86810c188
# ╟─ea17f0b0-6e3d-11eb-24a9-d7429c2f7a1c
# ╟─74881010-69a0-11eb-0f7b-174e062822d5
# ╟─650cbc40-6a30-11eb-005d-210b5b4b7320
# ╟─cb7ae490-6eca-11eb-10b3-ebda08aee935
# ╟─ab46b930-70c1-11eb-3e81-bf4b5fda7de6
# ╟─2684f1d0-6ecd-11eb-3254-7d4956805de9
# ╟─d3a34e42-6ed0-11eb-3a63-9b1a2cd29fde
# ╟─d4845f70-6ed0-11eb-17bf-3f684368f247
# ╟─b536f950-70c1-11eb-1f17-9939a8b0c241
# ╟─fe797dfe-6ed0-11eb-0a1c-f12aed1aedc5
# ╟─15e6c720-6ed4-11eb-01a5-e5670049de1a
# ╟─b883da60-70c1-11eb-29f4-395359a6cb01
# ╟─a60ab840-6ed2-11eb-09eb-39c6e752dce8
# ╟─64a6fa90-6edb-11eb-3e7c-83836ffe0ad6
# ╟─be39f340-70c1-11eb-32e8-1375297fb833
# ╟─6d6ab7b0-6ed2-11eb-0a14-116ffc586617
# ╟─3b3a7ce0-6eef-11eb-1c15-dd5f7a07424a
# ╟─b212fcc0-6eef-11eb-23af-6d8dcaef4fcc
# ╟─8231568e-6ef0-11eb-32ab-450855d94b94
# ╟─742234d0-6eef-11eb-39cb-49b7ec370a90
# ╟─80418290-6ef2-11eb-157c-6d31f48c50b5
# ╟─8149cad0-6ef2-11eb-321f-f54f84c1c7c0
# ╟─8715e410-6eef-11eb-1326-f360026efe4b
# ╟─cfc97700-6ef2-11eb-0887-a323d911410e
# ╟─d09a82a0-6ef2-11eb-2a25-d153d45e0761
# ╟─c82be110-70c1-11eb-2145-3df3e649304d
# ╟─ddc45070-6ed2-11eb-205e-57d941c5d670
# ╟─55af6e6e-6ef7-11eb-1bba-adc8d062797e
# ╟─d6e9fcf0-70c1-11eb-0df6-8f6cef676371
# ╟─88a02590-6cd6-11eb-080b-437e5a93d25c
# ╟─2289b110-6a27-11eb-2ba0-0735998426e8
# ╟─edafc2d0-70c1-11eb-0cb8-ef3150995f11
# ╟─7606a440-6cd6-11eb-1adb-bd52f7a637da
# ╟─449534f0-6a27-11eb-0ca5-d1b0e4ce75c2
# ╟─a01194c0-6cd6-11eb-36cd-edde6d7b6076
# ╟─d18ecd10-6cd6-11eb-235e-3b9a6bbe040d
# ╟─3593cfde-6cd7-11eb-0102-2175cdf86cae
# ╟─6c04582e-6a64-11eb-3fc5-572e3489a0b7
# ╟─b5dd4960-6cb9-11eb-2e03-530f378cb25a
# ╟─f94a7ea2-70c1-11eb-009d-7184b6bb72da
# ╟─0e4c40c0-6cb9-11eb-148a-e3004deca84d
# ╟─250c3a40-6cb9-11eb-0a5f-23b3bddb6875
# ╟─ccd392f0-6caa-11eb-2775-0bb711433969
# ╟─25fdce90-6cab-11eb-0bf1-6b67009a90fc
# ╟─c463b470-6cae-11eb-0a61-239e567d5207
# ╟─d0170e10-6cbe-11eb-25e4-ad41da12d808
# ╟─05c71aa0-6cbf-11eb-3785-3da0793b5308
# ╟─74fd6910-6cbf-11eb-13eb-85d3c632aeaf
# ╟─fdf2a9f0-70c1-11eb-3627-6df6c6808da4
# ╟─b1d58320-6cc1-11eb-1c06-a37cd10649c4
# ╟─c64daf82-6cc1-11eb-1acf-1db06fb1c44d
# ╟─8ae327d0-6cc2-11eb-1e64-f9440a711075
# ╟─58986650-6cc2-11eb-198f-4f39b15c41d8
# ╟─1ba4cd9e-6cc3-11eb-055a-bbefc004eaa9
# ╟─2ad951fe-6cc3-11eb-2d2e-61b21e39fa03
# ╟─660072a0-6cc3-11eb-1755-addce896fa8d
# ╟─02377f90-70c2-11eb-0f0b-df189837f921
# ╟─4993c990-6cd8-11eb-38b3-21c034f91b5f
# ╟─b66138e0-6cd9-11eb-10c8-55281956c83b
# ╟─b85ab650-6d86-11eb-0146-87a3201f8b18
# ╟─1402a9e0-6d8c-11eb-1558-fbf2b9d26659
# ╟─b7b00000-6cd9-11eb-1144-e14e2907c721
# ╟─dba37dc0-6cd9-11eb-225e-3300e82338c0
# ╟─de0e6fc0-6d88-11eb-21a1-a107659e5f43
# ╟─efcd8a22-6cd9-11eb-2eb8-c7ef097ec62b
# ╟─0214ccc0-6cda-11eb-13e6-41e668be1e48
# ╟─860da380-6d89-11eb-1e6b-73934e94db2f
# ╟─1103a530-70c2-11eb-27e1-8757bd6cb16a
# ╟─93048530-6d8f-11eb-20a5-a5c67dbe81c9
# ╟─9d851e70-6d8f-11eb-3ef7-3dab84054680
# ╟─c6eb8ac0-6e01-11eb-0875-85a52cc74785
# ╟─2eb8ee50-70c2-11eb-19ac-9b4736271733
# ╟─c43deb60-6e0b-11eb-2a08-8b25d9ecad6d
# ╟─f91d9a80-6e09-11eb-22fc-75f83a6e2013
# ╟─35c06930-6e0b-11eb-0c5c-2fa0acd69a4c
# ╟─6c6fea90-705f-11eb-24ac-990a92d783e3
# ╟─6d129330-705f-11eb-03c0-29869e426506
# ╠═5ca0c410-6ec3-11eb-14a2-ab87f05a3fa7
# ╟─3bbeabd0-70c2-11eb-1293-73cf076b5fcf
# ╟─8b273fb0-6ec5-11eb-0ebd-f3d33c769b59
# ╠═9aa1cdc0-6ec5-11eb-1f87-7d6b1e49536d
# ╟─37b16340-6cd8-11eb-0d5d-29c56bec1d00
# ╟─d55f70e0-6e46-11eb-3c94-c95a3cdce412
# ╟─c3c71ff0-6f17-11eb-163b-e5cd9c336409
# ╟─a694fd50-7087-11eb-146e-6d150bca4da2
# ╟─d5b38670-6f19-11eb-032f-cdb6824ca2a3
# ╟─1260f192-6f1d-11eb-2a12-b33e08144abe
# ╟─a2cbc050-7087-11eb-14ae-2f5383f2ea91
# ╟─dd3ce9a0-6f22-11eb-2dac-5b18aa14be35
# ╟─9f05deb0-7087-11eb-2b05-cd59b3abf3cb
# ╟─ab5f6180-6f25-11eb-18aa-c5c2de18eff5
# ╟─97d7f2e0-7087-11eb-2eee-7b59e972786f
# ╟─d9777220-705f-11eb-139d-ffd779019667
# ╟─2587cf30-7064-11eb-2091-f560d74047a1
# ╟─859929a2-7064-11eb-3511-a702f424f6af
# ╟─8f389cc0-7087-11eb-2f5f-f5eb7d684aec
# ╟─4d999ce0-7066-11eb-0231-ebb200cb7bf5
# ╠═c6ced170-7066-11eb-24bf-efe20f3721e9
# ╟─89be0640-7087-11eb-1702-1f6c419797c3
# ╟─e4fad130-7066-11eb-237c-631c1758c299
# ╠═d60c1d80-7068-11eb-10c1-8f4071a8024f
# ╟─4ce20fe0-706a-11eb-3ecf-d734f9f53e8e
# ╟─8291a110-7087-11eb-2ea3-9525931c80b2
# ╟─bb43fa80-706e-11eb-3dbe-498a6be4adf4
# ╟─1fd0fa90-7086-11eb-3db1-8552de51cb38
# ╟─d02aa01e-706e-11eb-3deb-2ffa303731f2
# ╟─621935c0-7086-11eb-0e7f-eb59845a0faa
# ╟─7a073d10-7088-11eb-1930-519022040b80
# ╟─4e5054d0-7089-11eb-356d-c13ea1f19ee7
# ╟─60b568c0-70c2-11eb-00fc-2702cc297bcb
# ╟─7924b62e-7091-11eb-0150-0d4cd784eb7f
# ╠═e7d77560-7094-11eb-1eda-8fb4b7457860
# ╟─ef215fc0-6e46-11eb-1804-d5f302cb9402
# ╟─e2580f00-6e46-11eb-21c8-a59b678acc9b
# ╟─4f2c5290-70ad-11eb-2871-4bcc5ee5a3f1
# ╟─6a028b10-70c2-11eb-337d-f79d7c5a4c08
# ╟─927e1910-70ae-11eb-1eb1-bbaf8d8f3f0a
# ╟─4a62c520-70c4-11eb-3b01-7509ea0780db
# ╟─7a30dac0-70ac-11eb-3f3a-a39482d6db94
# ╟─2b7c00e2-70c4-11eb-1d32-a78febc6988e
# ╟─737c1490-70c2-11eb-3871-f52255abe25d
# ╟─3e940100-70c4-11eb-2d44-85cf1f1ee510
# ╟─af3987f2-70a5-11eb-3823-35a58b5168d3
# ╟─bb66b990-70c2-11eb-229d-29b5c6bbb953
# ╟─197655c0-70b1-11eb-15f0-33a676325c4d
# ╟─27b6aa60-7096-11eb-0540-5345b4adef0e
# ╟─c4806fd2-70c2-11eb-2018-896eebbc6678
# ╟─4ba4ae40-70b4-11eb-2e77-ad23fd5b4b05
# ╟─694fa1b0-70b5-11eb-1a5a-a7229cbce5af
# ╟─c17682a2-70ab-11eb-25df-4d24e77bca3d
# ╟─b8c3c530-70a3-11eb-3c92-8d9d91a6899a
# ╟─14047c60-70b2-11eb-102f-db6edc6c3dd8
# ╟─d577aa40-70ab-11eb-3b91-7df7158f3dba
# ╟─c1b76060-70a4-11eb-389e-69d56b899820
# ╟─a1be8780-70b2-11eb-0f1d-1f27e962316f
# ╟─f817d690-6e46-11eb-04e1-bf2ec2655a32
# ╟─68ec2f80-70b6-11eb-28fe-f7bc1eadd63d
# ╟─bedb8310-70c4-11eb-115b-a5b2f9b05ea7
# ╟─d7d1c5e0-70b6-11eb-022b-8788a82085e4
# ╟─d602dbd0-70c2-11eb-1722-335f1b7045b6
# ╟─8a3dae00-6e4c-11eb-0d6c-2d6b4e28112e
# ╟─03be6f10-673d-11eb-3938-99159c46b44c
# ╟─dfbc2d70-70c2-11eb-03e0-2b5748d95770
# ╟─c16cd0f0-69a0-11eb-39e3-49c4e9bf7a4e
# ╟─cc88e6e0-69a0-11eb-14fb-1f10262af8d7
