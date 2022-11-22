import { Contract, utils } from 'ethers';
import {
	EXCHANGE_CONTRACT_ABI,
	EXCHANGE_CONTRACT_ADDRESS,
	TOKEN_CONTRACT_ABI,
	TOKEN_CONTRACT_ADDRESS,
} from '../constants';

export const addLiquidity = async (
	signer,
	addCDAmountWei,
	addEtherAmountWei
) => {
	try {
		const tokenContract = new Contract(
			TOKEN_CONTRACT_ADDRESS,
			TOKEN_CONTRACT_ABI,
			signer
		);
		const exchangeContract = new Contract(
			EXCHANGE_CONTRACT_ADDRESS,
			EXCHANGE_CONTRACT_ABI,
			signer
		);
		let tx = await tokenContract.approve(
			EXCHANGE_CONTRACT_ADDRESS,
			addCDAmountWei.toString()
		);
		await tx.wait();

		tx = await exchangeContract.addLiquidity(addCDAmountWei, {
			value: addEtherAmountWei,
		});
		await tx.wait();
	} catch (error) {
		console.error(error);
	}
};

//calculateCD calculates the CD tokens that need to be added to the liquidity given `_addEtherAmountWei` amount of ether
export const calculateCD = async (
	_addEther = '0',
	etherReserve,
	cdTokenReserve
) => {
	try {
		//`_addEther` is a string, we need to convert it to a Bignumber
		const _addEtherAmountWei = utils.parseEther(_addEther);
		// The ratio we follow is (amount of Crypto Dev tokens to be added) / (Crypto Dev tokens balance) = (Eth that would be added) / (Eth reserve in the contract)
		const cryptoDevTokenAmount = _addEtherAmountWei
			.mul(cdTokenReserve)
			.div(etherReserve);
		return cryptoDevTokenAmount;
	} catch (error) {
		console.error(error);
	}
};
