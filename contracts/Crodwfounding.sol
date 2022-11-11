// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract crodwfounding is Ownable {

    using SafeMath for uint256;
    
    uint public totalFounding = 0;

    uint public basePorcentaje = 10000;
  
  //FEE DEPOSITOS
    uint public feeDeposit = 200;
    uint public feeRestanteDesposit = basePorcentaje.sub(feeDeposit);

  //FEE RECLAMO DE GANANCIAS
    uint public claimfee = 1000;
    uint public claimFeeFail = basePorcentaje.sub(claimfee);

  //FEE SI NO SE LLENA LA POOL
   uint public feeNoComplet = 1000;
   uint public restanNoCompleteFee = basePorcentaje.sub(feeNoComplet);

   address addrFee = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ;

    IERC20 public DAI;

    struct Datos {
      string tittle;
      string description;
      string urlImg;
    }

    struct Niveles{
        uint bronze;
        uint silver;
        uint gold;
        uint diamond;
        uint platinum;
        uint palladium;
    }

    struct PoolFounding {
        uint pid;
        address creator;
        uint totalToCollect;
        Niveles nivel;
        uint income;
        uint deadline;
        address[] users;
        Datos dato;
        bool active;
    }

    struct Inversor {
        address inversor;
        uint pid;
        uint cantidadIngresada;
        uint cantidadConFee;
        string nivel;
        string mail;
        bool devuelto;
    }

    constructor(address _dai){
        DAI = IERC20 (_dai);
    }


    event createFounding (uint pid, address creator, uint totalToCollect );

    event sendInversion (uint pid, uint amount, address inversor);


    mapping(uint => PoolFounding) public poolFounding;

    mapping(uint256 => mapping(address => Inversor)) public inversor;
    
    mapping(uint => mapping(address => bool)) public isConfirmed;


///agregar cantidad minima
    function createCrodwFounding( string memory _title, string  memory _description,
        uint _totalToCollect, uint _bronze, 
        uint _silver,
        uint _gold,
        uint _diamond,
        uint _platinum,
        uint _palladium,
        uint _deadline, address _creator) public onlyOwner {

        uint totalCollect =  _totalToCollect.mul(1000000);
        string memory title = _title;
        string memory description = _description;
       // string memory url = _url;
        uint bronze = _bronze.mul(1000000);
        uint silver = _silver.mul(1000000);
        require(bronze < silver , "bronze tiene q ser menor a silver");
        uint gold = _gold.mul(1000000);
        require(silver < gold , "silver tiene q ser menor a gold");
        uint diamon = _diamond.mul(1000000);
        require(gold < diamon , "gold tiene q ser menor a diamon");
        uint platinum = _platinum.mul(1000000);
        require(diamon < platinum , "diamon tiene q ser menor a platinum");
        uint palladium = _palladium.mul(1000000);
        require(platinum< palladium, "menor que platinum");


        uint deadLIne = _deadline.mul(1 days);  
        uint dayDealine = block.timestamp.add(deadLIne);

        PoolFounding storage pool = poolFounding[totalFounding];
          pool.pid = totalFounding;
          pool.creator = _creator;
          pool.totalToCollect = totalCollect;
          pool.nivel = Niveles(bronze,silver, gold, diamon,platinum, palladium);
          pool.income = 0;
          pool.deadline = dayDealine;
          pool.dato = Datos(title,description,title);
          pool.active = true;
 
          totalFounding += 1;

        emit createFounding (totalFounding, _creator, totalCollect);
    } 

    function depositMoney(uint _pid, uint _amount, string memory _mail)public {
        PoolFounding storage pool = poolFounding[_pid];
        uint amount = _amount.mul(1000000);
        require(pool.deadline > block.timestamp," ya expiroooo");
        require(pool.active == true, "no esta activa"); 
        require(amount.add(pool.income) <= pool.totalToCollect.add(pool.totalToCollect.mul(feeDeposit).div(basePorcentaje)), "poner menos que ya esta casi completa ");
        uint256 allowance = IERC20(DAI).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint amounFee = amount.mul(feeDeposit).div(basePorcentaje);
        uint amountFinal = amount.mul(feeRestanteDesposit).div(basePorcentaje);
        if(amount > 0){
            require(IERC20(DAI).transferFrom(msg.sender, addrFee, amounFee ),"no se envioo");   
            require(IERC20(DAI).transferFrom(msg.sender, address(this),amountFinal),"nose envio"); 
        }

        Inversor storage infoInver = inversor[_pid][msg.sender];

        if(isConfirmed[_pid][msg.sender] == true){
            infoInver.cantidadIngresada += amountFinal;
            infoInver.cantidadConFee += amounFee;
            pool.income +=amountFinal;
            infoInver.nivel = nivel(_pid, infoInver.cantidadIngresada);
        }else{
             Inversor memory newInersor = Inversor(
                msg.sender,
                _pid,
                amountFinal,
                amounFee,
                nivel(_pid, amountFinal),
                _mail,
                false
                );

                pool.users.push(msg.sender);
                inversor[_pid][msg.sender] = newInersor;
                isConfirmed[_pid][msg.sender] = true;
                pool.income +=amountFinal;
        }

        emit sendInversion(_pid, amountFinal, msg.sender);

    }


    function nivel(uint _pid, uint _amount) internal  returns (string memory nivel1){
        PoolFounding storage pool = poolFounding[_pid];
        Inversor storage infoInver = inversor[_pid][msg.sender];
          if(_amount < pool.nivel.bronze){
              return infoInver.nivel = "BRONZE";
            } else if(_amount < pool.nivel.silver ){
              return  infoInver.nivel = "SILVER";
            }else if(_amount < pool.nivel.gold ){
              return  infoInver.nivel = "GOLD";
            }else if(_amount < pool.nivel.diamond ){
              return  infoInver.nivel = "DIAMOND";
            }else if(_amount < pool.nivel.platinum ){
              return  infoInver.nivel = "PLATINIUM";
            }else if(_amount < pool.nivel.palladium ||  _amount > pool.nivel.palladium){
              return  infoInver.nivel = "PALLADIUM";
          }
    }
            

    function claimReward(uint _pid) public {
        PoolFounding storage pool = poolFounding[_pid];
          require(msg.sender == pool.creator, "vos no podes");
          require(pool.income >= pool.totalToCollect, "todavia no esta completa");
          require(pool.active == true, "no esta activa");
      //  require(pool.deadline < block.timestamp," no expiroooo aun");
        if( pool.totalToCollect > 0){
            IERC20(DAI).approve(address(this),pool.totalToCollect);
            require(IERC20(DAI).transferFrom(address(this), addrFee ,pool.totalToCollect.mul(claimfee).div(basePorcentaje)),"DASDAS"); 
            require(IERC20(DAI).transferFrom(address(this), pool.creator ,pool.totalToCollect.mul(claimFeeFail).div(basePorcentaje)),"DASDAS");
        }
        pool.active = false;
    }


    function devolverRewards(uint _pid) public onlyOwner{
      PoolFounding storage pool = poolFounding[_pid];
      require(pool.active == true, "no esta activa");
      require(pool.deadline < block.timestamp," no expiroooo aun");
      uint cantidadSobrante = pool.income;
      for(uint i = 0; i< pool.users.length; i++){
        Inversor storage infoInver = inversor[_pid][pool.users[i]];
        if(infoInver.devuelto == false){
         IERC20(DAI).approve(address(this),pool.totalToCollect);
         require(IERC20(DAI).transferFrom(address(this), infoInver.inversor , infoInver.cantidadIngresada.mul(restanNoCompleteFee).div(basePorcentaje)),"DASDAS");
        }
        infoInver.devuelto = true; 
      }
        uint cantidadFee = cantidadSobrante.mul(feeNoComplet).div(basePorcentaje);
        require(IERC20(DAI).transferFrom(address(this), addrFee , cantidadFee),"DASDAS");
        pool.active = false;
    }


      function claimRewardCadauNO(uint _pid) public{
        PoolFounding storage pool = poolFounding[_pid];
        require(pool.active == true, "no esta activa");
        require(pool.deadline < block.timestamp," no expiroooo aun");
        Inversor storage infoInver = inversor[_pid][msg.sender];
        if( pool.totalToCollect > 0){
            IERC20(DAI).approve(address(this),pool.totalToCollect);
            require(IERC20(DAI).transferFrom(address(this), addrFee ,infoInver.cantidadIngresada.mul(claimfee).div(basePorcentaje)),"DASDAS"); 
            require(IERC20(DAI).transferFrom(address(this), infoInver.inversor ,infoInver.cantidadIngresada.mul(claimFeeFail).div(basePorcentaje)),"DASDAS");
        }

        infoInver.devuelto = true;
    }



    

    function balanceDai() public view returns(uint balanceStable){
      uint balance = IERC20(DAI).balanceOf(address(this));
      return balance.div(1000000);
    }


    function addresPool (uint _pid) public view returns(address[] memory usuarios){
      PoolFounding storage pool = poolFounding[_pid]; 
      return pool.users;
    }



    function cambiarFee(uint _fee) public onlyOwner {
      feeDeposit= _fee;
      feeRestanteDesposit = basePorcentaje.sub(feeDeposit);
    }


    function cambiarFeeClaim(uint _fee) public onlyOwner {
      claimfee= _fee;
      claimFeeFail = basePorcentaje.sub(claimfee);
    }

      function cambiarFeeNoReclam(uint _fee) public onlyOwner {
      feeNoComplet= _fee;
      restanNoCompleteFee = basePorcentaje.sub(feeNoComplet);
    }

    function apagarPool (uint _pid) public onlyOwner {
       PoolFounding storage pool = poolFounding[_pid]; 
       pool.active = false;
    }


}