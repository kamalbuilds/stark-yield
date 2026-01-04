'use client';

import { useAccount, useContract, useSendTransaction } from '@starknet-react/core';
import { CONTRACTS, SY_ABI, TOKENIZER_ABI, ERC20_ABI } from '@/lib/contracts';
import { CallData, cairo } from 'starknet';

export function useStarkYieldContracts() {
    const { address } = useAccount();

    const { contract: syContract } = useContract({
        abi: SY_ABI as any,
        address: CONTRACTS.SY_XSTRK as `0x${string}`,
    });

    const { contract: tokenizerContract } = useContract({
        abi: TOKENIZER_ABI as any,
        address: CONTRACTS.TOKENIZER as `0x${string}`,
    });

    const { sendAsync: sendTransaction, data: txData, isPending } = useSendTransaction({});

    // Approve xSTRK for SY contract
    const approveXSTRK = async (amount: bigint) => {
        if (!address) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.XSTRK,
                entrypoint: 'approve',
                calldata: CallData.compile([
                    CONTRACTS.SY_XSTRK,
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Deposit xSTRK into SY contract to get SY tokens
    const depositToSY = async (amount: bigint) => {
        if (!address || !syContract) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.SY_XSTRK,
                entrypoint: 'deposit',
                calldata: CallData.compile([
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Withdraw from SY to get xSTRK back
    const withdrawFromSY = async (amount: bigint) => {
        if (!address || !syContract) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.SY_XSTRK,
                entrypoint: 'withdraw',
                calldata: CallData.compile([
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Approve SY for Tokenizer contract
    const approveSYForTokenizer = async (amount: bigint) => {
        if (!address) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.SY_XSTRK,
                entrypoint: 'approve',
                calldata: CallData.compile([
                    CONTRACTS.TOKENIZER,
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Tokenize SY into PT + YT
    const tokenize = async (amount: bigint) => {
        if (!address || !tokenizerContract) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.TOKENIZER,
                entrypoint: 'tokenize',
                calldata: CallData.compile([
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Approve PT and YT for Tokenizer to redeem
    const approvePTYTForTokenizer = async (amount: bigint) => {
        if (!address) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.PT_TOKEN,
                entrypoint: 'approve',
                calldata: CallData.compile([
                    CONTRACTS.TOKENIZER,
                    cairo.uint256(amount),
                ]),
            },
            {
                contractAddress: CONTRACTS.YT_TOKEN,
                entrypoint: 'approve',
                calldata: CallData.compile([
                    CONTRACTS.TOKENIZER,
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Redeem PT + YT for SY
    const redeem = async (amount: bigint) => {
        if (!address || !tokenizerContract) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.TOKENIZER,
                entrypoint: 'redeem',
                calldata: CallData.compile([
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Redeem PT only after maturity
    const redeemPT = async (amount: bigint) => {
        if (!address || !tokenizerContract) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.TOKENIZER,
                entrypoint: 'redeem_pt',
                calldata: CallData.compile([
                    cairo.uint256(amount),
                ]),
            }
        ]);
    };

    // Claim accrued yield from YT
    const claimYield = async () => {
        if (!address) return;

        return await sendTransaction([
            {
                contractAddress: CONTRACTS.YT_TOKEN,
                entrypoint: 'claim_yield',
                calldata: CallData.compile([address]),
            }
        ]);
    };

    return {
        syContract,
        tokenizerContract,
        approveXSTRK,
        depositToSY,
        withdrawFromSY,
        approveSYForTokenizer,
        tokenize,
        approvePTYTForTokenizer,
        redeem,
        redeemPT,
        claimYield,
        isPending,
        txHash: txData?.transaction_hash,
    };
}
